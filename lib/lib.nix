{
  runCommand,
  nickel,
  system,
  lib,
}: let
  # Export a Nix value to be consumed by Nickel
  typeField = "$__nixel_type";

  isInStore = lib.hasPrefix builtins.storeDir;

  # We use this structure to keep track of all derivations that are visited in exportForNickel:
  #   {
  #     value :: Any;  # the value that can be serialised to JSON to pass to Nickel
  #     context :: {   # accumulates all derivations that are met during conversion
  #       ... :: {     # key is drvPath of the derivation (any unique identifier would suffice)
  #         ... ::     # subkey is outputName of the derivation to keep different outputs separate
  #           Derivation;  # derivation as a opaque Nix object
  #       };
  #     };
  #   }
  # After we collect this data, we pass `value` to Nickel via JSON and keep `context`.
  # When we convert Nickel values back to Nix, we substitute all attrsets with
  # $__nixel_type == "nixDerivation" with values from the context, preserving
  # original derivations without having to resort to impure methods like importing drvPath directly.
  #
  # NOTE: This `context` is neither Nix string context nor Nickel string context
  # it has nothing to do with strings and everything to do with keeping references
  # to the derivation objects on Nix side

  valueWithContext = {
    create = value: context: {inherit value context;};
    emptyContext = value: valueWithContext.create value {};
    mergeContexts = lib.recursiveUpdateUntil (p: _: _: lib.length p < 2);
    setAttr = set: name: value: {
      value = set.value // {${name} = value.value;};
      context = valueWithContext.mergeContexts set.context value.context;
    };
    prependToList = value: list: {
      value = [value.value] ++ list.value;
      context = valueWithContext.mergeContexts value.context list.context;
    };
  };

  exportForNickel = value: let
    type = builtins.typeOf value;
  in
    if (type == "set")
    then
      (
        if (value.type or "" == "derivation")
        then
          valueWithContext.create (
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
          ) {
            ${builtins.unsafeDiscardStringContext value.drvPath}.${value.outputName} = value;
          }
        else
          builtins.foldl'
          (
            acc: eltName:
              valueWithContext.setAttr acc eltName (exportForNickel value.${eltName})
          )
          (valueWithContext.emptyContext {})
          (builtins.attrNames value)
      )
    else if (type == "list")
    then
      builtins.foldl'
      (
        acc: elt:
          valueWithContext.prependToList (exportForNickel elt) acc
      )
      (valueWithContext.emptyContext [])
      value
    else if (type == "lambda")
    then throw "Can’t export a function"
    else if (type == "path" && isInStore value)
    then valueWithContext.emptyContext (builtins.toString value)
    else valueWithContext.emptyContext value;

  # Take a symbolic derivation (a datastructure representing a derivation), as
  # produced by Nickel, and transform it into valid arguments to
  # `derivation`
  prepareDerivation = system: value:
    (builtins.removeAttrs value ["build_command" "env" "structured_env" "attrs" "packages"])
    // {
      system =
        if value ? system
        then "${value.system.arch}-${value.system.os}"
        else system;
      builder = value.build_command.cmd;
      args = value.build_command.args;
      __structuredAttrs = true;
    }
    // value.attrs;

  # Import a Nickel value produced by the Nixel DSL
  importFromNickel = context: system: baseDir: value: let
    type = builtins.typeOf value;
    isNickelDerivation = type: type == "nickelDerivation";
    importFromNickel_ = importFromNickel context system baseDir;
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
          then context.${value.drvPath}.${value.outputName or "out"}
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
    exportedPkgsNcl,
  }: let
    sources = builtins.path {
      path = baseDir;
      # TODO: filter .ncl files
      # filter =
    };

    exportedJSON =
      builtins.toFile
      "inputs.json"
      (builtins.unsafeDiscardStringContext (builtins.toJSON exportedPkgsNcl));

    nickelWithImports = builtins.toFile "eval.ncl" ''
      let params = {
        inputs = import "${exportedJSON}",
        system = "${system}",
        nix = import "${./..}/lib/nix.ncl",
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
      let contracts = (import "${./..}/lib/nix.ncl").contracts in
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
          valueWithContext.setAttr acc inputId
          (exportForNickel (runCommand (builtins.baseNameOf as_nix_path) {}
              "cp -r ${as_nix_path} $out"))
      else if builtins.hasAttr inputTakeFrom flakeInputs
      then let
        input =
          flakeInputs.${inputTakeFrom}.legacyPackages.${system}
          or flakeInputs.${inputTakeFrom}.packages.${system};

        pkgPath = declaredInputs.${inputId}.path or [inputId];
      in
        if lib.hasAttrByPath pkgPath input
        then valueWithContext.setAttr acc inputId (exportForNickel (lib.getAttrFromPath pkgPath input))
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
    lib.lists.foldr addPackage (valueWithContext.emptyContext {}) (builtins.attrNames declaredInputs);

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
    pkgsExportResult = exportForNickel exportedPkgs.value;
    fileToCall = computeNickelFile {
      inherit baseDir nickelFile;
      exportedPkgsNcl = pkgsExportResult.value;
    };
  in
    valueWithContext.create
    (
      runCommand "nickel-res.json" {} ''
        ${nickel}/bin/nickel -f ${fileToCall} export > $out
      ''
    ) (valueWithContext.mergeContexts pkgsExportResult.context exportedPkgs.context);

  # Import a Nickel expression as a Nix value. flakeInputs are where the packages
  # passed to the Nickel expression are taken from. If the Nickel expression
  # declares an input hello from input "nixpkgs", then flakeInputs must have an
  # attribute "nixpkgs" with a package "hello".
  importNcl = baseDir: nickelFile: flakeInputs: let
    nickelResult = callNickel {
      inherit nickelFile baseDir flakeInputs;
    };
  in
    {rawNickel = nickelResult.value;}
    // lib.traceVal (importFromNickel nickelResult.context system baseDir (builtins.fromJSON
        (builtins.unsafeDiscardStringContext (builtins.readFile nickelResult.value))));
in {inherit importNcl;}
