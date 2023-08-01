{
  runCommand,
  nickel,
  system,
  lib,
  flakeRoot,
}: let
  # Export a Nix value to be consumed by Nickel
  typeField = "$__nixel_type";

  isInStore = lib.hasPrefix builtins.storeDir;

  # Take a symbolic derivation (a datastructure representing a derivation), as
  # produced by Nickel, and transform it into valid arguments to
  # `derivation`
  prepareDerivation = system: value:
    value
    // {
      system =
        if value.system != null
        then value.system
        else system;
    };

  # Import a Nickel value produced by the Nixel DSL
  importFromNickel = flakeInputs: system: baseDir: value: let
    type = builtins.typeOf value;
    isNickelDerivation = type: type == "nickelDerivation";
    importFromNickel_ = importFromNickel flakeInputs system baseDir;
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
            value.nix_drv);
          in
            derivation prepared
          else if nixelType == "nixString"
          then builtins.concatStringsSep "" (builtins.map importFromNickel_ value.fragments)
          else if nixelType == "nixPath"
          then baseDir + "/${value.path}"
          else if nixelType == "nixInput"
          then
          let
            attr_path = value.attr_path;
            possibleAttrPaths = [
             ([ value.input ] ++ attr_path)
             ([ value.input "packages" system ] ++ attr_path)
             ([ value.input "legacyPackages" system ] ++ attr_path)
            ];
            notFound = throw "Missing input \"${value.input}.${lib.strings.concatStringsSep "." attr_path}\"";
            chosenAttrPath = lib.findFirst
              (path: lib.hasAttrByPath path flakeInputs)
              notFound
              possibleAttrPaths;
          in
            lib.getAttrFromPath chosenAttrPath flakeInputs
          else builtins.mapAttrs (_: importFromNickel_) value
      )
    else if (type == "list")
    then builtins.map importFromNickel_ value
    else value;

  # Generate a Nickel program that evaluates the nickel-nix output, passing
  # the given exported packages, and write it to outFile.
  computeNickelFile = {
    baseDir,
    nickelFile
  }: let
    sources = builtins.path {
      path = baseDir;
      # TODO: filter .ncl files
      # filter =
    };

    nickelWithImports = builtins.toFile "eval.ncl" ''
      let params = {
        system = "${system}",
      }
      in
      let nix = import "${flakeRoot}/lib/nix.ncl" in

      let nickel_expr | nix.contracts.NixelExpression =
        import "${sources}/${nickelFile}" in

      (nickel_expr & params).output
    '';
  in
    nickelWithImports;

  # Call Nickel on a given Nickel expression with the inputs declared in it.
  # See importNcl for details about the flakeInputs parameter.
  callNickel = {
    nickelFile,
    flakeInputs,
    baseDir,
  }: let
    fileToCall = computeNickelFile {
      inherit baseDir nickelFile;
    };
  in
  runCommand "nickel-res.json" {
    ___ = flakeRoot; # Make it available in the sandbox as the lockfile relies on it
  } ''
  ${nickel}/bin/nickel -f ${fileToCall} export > $out
  '';

  # Import a Nickel expression as a Nix value. flakeInputs are where the packages
  # passed to the Nickel expression are taken from. If the Nickel expression
  # declares an input hello from input "nixpkgs", then flakeInputs must have an
  # attribute "nixpkgs" with a package "hello".
  importNcl = baseDir: nickelFile: flakeInputs: let
    nickelResult = callNickel {
      inherit nickelFile baseDir flakeInputs;
    };
  in
    {rawNickel = nickelResult;}
    // (importFromNickel flakeInputs system baseDir (builtins.fromJSON
        (builtins.unsafeDiscardStringContext (builtins.readFile nickelResult))));
in {inherit importNcl;}
