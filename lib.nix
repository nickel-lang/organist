{
  runCommand,
  nickel,
  system,
  lib,
  nickel-nix-internals,
}: let
  # Export a Nix value to be consumed by Nickel
  typeField = "$__nixel_type";

  isInStore = path: let
    sd = builtins.storeDir;
  in
    builtins.substring 0 (builtins.stringLength sd) path == sd;

  exportForNickel = value: let
    type = builtins.typeOf value;
  in
    if (type == "set")
    then
      (
        if (value.type or "" == "derivation")
        then
          {
            "${typeField}" = "nixDerivation";
            inherit
              (value)
              drvPath
              outputName
              ;
            outputPath = value.outPath;
          }
          // (
            if value ? version
            then {inherit (value) version;}
            else {}
          )
        else builtins.mapAttrs (_: exportForNickel) value
      )
    else if (type == "list")
    then builtins.map exportForNickel value
    else if (type == "lambda")
    then throw "Can’t export a function"
    else if (type == "path" && isInStore value)
    then builtins.toString value
    else value;

  # Take a symbolic derivation (a datastructure representing a derivation), as
  # produced by Nickel, and transform it into valid arguments to
  # `derivation`
  prepareDerivation = system: value:
    (builtins.removeAttrs value ["build_command" "env" "structured_env"])
    // {
      system =
        if value ? system
        then "${value.system.arch}-${value.system.os}"
        else system;
      builder = value.build_command.cmd;
      args = value.build_command.args;
    }
    // value.env;

  # Import a Nickel value produced by the Nixel DSL
  importFromNickel = system: baseDir: value: let
    type = builtins.typeOf value;
    isNickelDerivation = type: type == "nickelDerivation";
    importFromNickel_ = importFromNickel system baseDir;
  in
    if (type == "set")
    then
      (
        let
          nixelType = value."${typeField}" or "";
        in
          if isNickelDerivation nixelType
          then let
            prepared = prepareDerivation system (builtins.mapAttrs (_:
              importFromNickel_)
            value);
          in
            derivation prepared
          else if nixelType == "nixDerivation"
          then (import value.drvPath).${value.outputName or "out"}
          else if nixelType == "nixString"
          then builtins.concatStringsSep "" (builtins.map importFromNickel_ value.fragments)
          else if nixelType == "nixPath"
          then baseDir + "/${value.path}"
          else builtins.mapAttrs (_: importFromNickel_) value
      )
    else if (type == "list")
    then builtins.map importFromNickel_ value
    else value;

  # Generate a Nickel program that evaluates the nickel-nix output, passing
  # the given exported packages, and write it to outFile.
  computeNickelFile = {
    baseDir,
    nickelFile,
    exportedPkgs,
  }: let
    sources = builtins.path {
      path = baseDir;
      # TODO: filter .ncl files
      # filter =
    };

    exportedJSON =
      builtins.toFile
      "inputs.json"
      (builtins.unsafeDiscardStringContext (builtins.toJSON (exportForNickel exportedPkgs)));

    nickelWithImports = builtins.toFile "eval.ncl" ''
      let params = {
        inputs = import "${exportedJSON}",
        system = "${system}",
        nix = import "${./.}/nix.ncl",
      }
      in

      let nickel_expr | params.nix.NickelExpression =
        import "${sources}/${nickelFile}"
      in

      (nickel_expr & params).output
    '';
  in
    nickelWithImports;

  # Extract the inputs declared in the Nickel expression.
  extractInputs = {
    baseDir,
    nickelFile,
  }: let
    sources = builtins.path {
      path = baseDir;
      # TODO: filter .ncl files
      # filter =
    };
    fileToCall = builtins.toFile "extract-inputs.ncl" ''
      let contracts = import "${./.}/contracts.ncl" in
      let nickel_expr = import "${sources}/${nickelFile}" in
      nickel_expr.inputs_spec | {_: contracts.NickelInputSpec}
    '';
    result = runCommand "nickel-inputs.json" {} ''
      ${nickel}/bin/nickel -f ${fileToCall} export > $out
    '';
  in (builtins.fromJSON (builtins.readFile result));

  # Process the inputs declared in the Nickel expression, fetch the corresponding
  # Nix values, and export them to JSON to be directly usable by the nickel-nix
  # file
  exportInputs = {
    declaredInputs,
    flakeInputs,
    baseDir,
  }: let
    # inputId is the arbitrary name given by the Nickel expression to the
    # input.
    # For example,in
    # `input_specs = {foo = {input = "nixpkgs", path = ["gcc"]}}`
    # inputId is "foo". The package we want to get from nixpkgs is gcc.
    #
    # However, if no `path` is specified, `path` is taken to be `inputId`.
    addPackage = inputId: acc: let
      inputTakeFrom = declaredInputs.${inputId}.input;
    in
      # "sources" is a special type of input for files. They mimic Nix style
      # paths. We don't take them from flake inputs (where they aren't,
      # anyway), but create a simple derivation wrapper around them to pass
      # them to the Nickel side.
      # TODO: should we get rid of sources, now that we have `import_file` and
      # symbolic strings?
      if inputTakeFrom == "sources"
      then
        # TODO: could we use flakeInputs.self.outPath instead of passing
        # baseDir explicitly? Maybe, but the issue is that this path is the
        # path of the git directory, not the subdirectory of the flake.nix.
        # may need some massaging
        let
          as_nix_path =
            baseDir
            + "/${builtins.concatStringsSep "." declaredInputs.${inputId}.path}";
        in
          acc
          // {
            "${inputId}" =
              exportForNickel (runCommand (builtins.baseNameOf as_nix_path) {}
                "cp -r ${as_nix_path} $out");
          }
      else if builtins.hasAttr inputTakeFrom flakeInputs
      then let
        input =
          if inputTakeFrom == "nickel-nix-internals"
          then flakeInputs.${inputTakeFrom}
          else if inputTakeFrom == "nixpkgs"
          then flakeInputs.${inputTakeFrom}.legacyPackages.${system}
          else flakeInputs.${inputTakeFrom}.packages.${system};

        pkgPath = declaredInputs.${inputId}.path or [inputId];
      in
        if lib.hasAttrByPath pkgPath input
        then acc // {"${inputId}" = exportForNickel (lib.getAttrFromPath pkgPath input);}
        else
          builtins.throw ''
            Could not find package `${builtins.concatStringsSep "." pkgPath}`
            in input `${inputTakeFrom}`
          ''
      else
        builtins.throw ''
          The Nickel expression requires an input `${inputTakeFrom}` for input
          `${inputId}`, but no such input was forwarded to `importNcl` on the nix
          side. Forwarded inputs: ${
            builtins.toString (builtins.attrNames flakeInputs)
          }
        '';
  in
    lib.lists.foldr addPackage {} (builtins.attrNames declaredInputs);

  # Call Nickel on a given Nickel expression with the inputs declared in it.
  # See importNcl for details about the flakeInputs parameter.
  callNickel = {
    nickelFile,
    flakeInputs,
    baseDir,
  }: let
    declaredInputs =
      extractInputs
      {inherit baseDir nickelFile;};
    exportedPkgs =
      exportInputs
      {inherit declaredInputs flakeInputs baseDir;};
    fileToCall = computeNickelFile {inherit baseDir nickelFile exportedPkgs;};
  in
    runCommand "nickel-res.json" {} ''
      ${nickel}/bin/nickel -f ${fileToCall} export > $out
    '';

  # Import a Nickel expression as a Nix value. flakeInputs are where the packages
  # passed to the Nickel expression are taken from. If the Nickel expression
  # declares an input hello from input "nixpkgs", then flakeInputs must have an
  # attribute "nixpkgs" with a package "hello".
  importNcl = baseDir: nickelFile: flakeInputs: let
    flakeInputsWithInternals =
      flakeInputs
      // {
        nickel-nix-internals = builtins.mapAttrs (_: f: f flakeInputs) nickel-nix-internals;
      };
    nickelResult = callNickel {
      inherit nickelFile baseDir;
      flakeInputs = flakeInputsWithInternals;
    };
  in
    {rawNickel = nickelResult;}
    // lib.traceVal (importFromNickel system baseDir (builtins.fromJSON
        (builtins.unsafeDiscardStringContext (builtins.readFile nickelResult))));
in {inherit importNcl;}
