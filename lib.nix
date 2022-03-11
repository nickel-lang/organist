let
  # Export a Nix value to be consumed by Nickel
  exportForNickel = value:
      let type = builtins.typeOf value; in
      if (type == "set") then (
        if (value.type or "" == "derivation") then
          { type = "nixDerivation"; drvPath = value.drvPath; outputName = value.outputName; }
        else
          builtins.mapAttrs (_: exportForNickel) value
        )
      else if (type == "list") then builtins.map exportForNickel value
      else if (type == "lambda") then
        throw "Can’t export a function"
      else value;

  # Import a Nickel value produced by the Nixel DSL
  importFromNickel = mkShell: value:
    let
      type = builtins.typeOf value;
      isNickelDerivation = type: type == "nickelPackage" || type == "nickelShell";
      importFromNickel_ = importFromNickel mkShell;
    in
    if (type == "set") then (
      let valueType = value.type or ""; in
      if valueType == "nickelPackage" then
        derivation (builtins.mapAttrs (_: importFromNickel_) value)
      else if valueType == "nickelShell" then
        mkShell (builtins.mapAttrs (_: importFromNickel_) value)
      else if valueType == "nixDerivation" then
        (import value.drvPath).${value.outputName or "out"}
      else if valueType == "nixString" then
        builtins.concatStringsSep "" (builtins.map importFromNickel_ value.fragments)
      else
        builtins.mapAttrs (_: importFromNickel_) value
      )
    else if (type == "list") then
        builtins.map importFromNickel_ value
    else value;

  # Generate a Nickel program that evaluates the nickel-nix output, passing
  # the given exported packages, and write it to outFile.
  computeNickelFile = system: {nickelFile, exportedPkgs}:
    let
      exportedJSON = builtins.toFile
          "inputs.json"
          (builtins.unsafeDiscardStringContext (builtins.toJSON (exportForNickel exportedPkgs)));

      nickelWithImports = builtins.toFile "eval.ncl" ''
          let params = {
            pkgs = import "${exportedJSON}",
            system = "${system}",
            nix = import "${./nix.ncl}",
          } in
          let nickel_expr | params.nix.NickelExpression = import "${nickelFile}" in
          nickel_expr.output params
      '';

    in
    nickelWithImports;

  # Extract the inputs declared in the Nickel expression.
  extractInputs = {runCommand, nickel, system}: nickelFile:
    let
      fileToCall = builtins.toFile "extract-inputs.ncl" ''
        let nix = import "${./nix.ncl}" in
        let nickel_expr | nix.NickelExpression = import "${nickelFile}" in
        nickel_expr.inputs_spec
      '';
      result = runCommand "nickel-inputs.json" {} ''
        ${nickel}/bin/nickel -f ${fileToCall} export > $out
      '';
    in
    (builtins.fromJSON (builtins.readFile result));

  # Process the inputs declared in the Nickel expression, fetch the corresponding
  # Nix values, and export them to JSON to be directly usable by the nickel-nix
  # file
  exportInputs = system: lib: { declaredInputs, flakeInputs }:
    let
      pkgNames = builtins.attrNames declaredInputs;
      addPackage = name: acc:
        let inputName = declaredInputs."${name}".input; in
        if builtins.hasAttr inputName flakeInputs then
          let
            input =
              if inputName == "nixpkgs" then
                flakeInputs.${inputName}.legacyPackages.${system}
              else
                flakeInputs.${inputName}.${system}.packages;
          in
          if builtins.hasAttr name input then
            acc // {"${name}" = exportForNickel input.${name};}
          else
            builtins.throw ''
              Could not find package `${name}` in input `${inputName}`
            ''
        else
          builtins.throw ''
            The Nickel expression requires an input `${inputName}` for package
            `${name}`, but no such input was forwaded to importNcl on the nix
            side. Forwarded inputs: ${
                 builtins.toString (builtins.attrNames flakeInputs)
              }
          '';
    in
    lib.lists.foldr addPackage {} (builtins.attrNames declaredInputs);

  # Call Nickel on a given Nickel expression with the inputs declared in it.
  # See importNcl for details about the flakeInputs parameter.
  callNickel = { runCommand, nickel, system, lib, ... }@args: { nickelFile, flakeInputs }:
    let
      declaredInputs = extractInputs { inherit runCommand nickel system; } nickelFile;
      exportedPkgs = exportInputs system lib { inherit declaredInputs flakeInputs; };
      fileToCall = computeNickelFile system { inherit nickelFile exportedPkgs; };
    in

    runCommand "nickel-res.json" {} ''
      ${nickel}/bin/nickel -f ${fileToCall} export > $out
    '';

  # Import a Nickel expression as a Nix value. flakeInputs are where the packages
  # passed to the Nickel expression are taken from. If the Nickel expression 
  # declares an input hello from input "nixpkgs", then flakeInputs must have an
  # attribute "nixpkgs" with a package "hello".
  importNcl = { runCommand, nickel, system, lib, mkShell }@args: nickelFile: flakeInputs:
    let nickelResult = callNickel args { inherit nickelFile flakeInputs; }; in
    { rawNickel = nickelResult; }
    // (importFromNickel mkShell (builtins.fromJSON (builtins.readFile nickelResult)));

in
{ inherit importNcl; }
