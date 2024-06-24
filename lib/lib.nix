{
  runCommand,
  writeText,
  writeShellApplication,
  nickel,
  pkgs,
  system,
  lib,
  organistSrc,
}: let
  # Export a Nix value to be consumed by Nickel
  typeField = "$__organist_type";

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
  # Helper function that generates contents for "nickel.lock.ncl", see buildLockFile.
  buildLockFileContents = contents: let
    getLinesOne = indent: name: thing:
      if lib.isAttrs thing
      then
        [
          (indent + (lib.optionalString (name != null) "${name} = ") + "{")
        ]
        ++ lib.mapAttrsToList (getLinesOne (indent + "  ")) thing
        ++ [
          (indent + "}" + (lib.optionalString (name != null) ","))
        ]
      else [''${indent}${name} = import "${builtins.toString thing}",''];
  in
    lib.concatLines (lib.flatten (getLinesOne "" null contents));

  # A script that generates contents of "nickel.lock.ncl" file from a recursive attribute set of strings.
  # Example inputs:
  #   {
  #     organist = {
  #       builders = "/nix/store/...-source/builders.ncl";
  #       contracts = "/nix/store/...-source/contracts.ncl";
  #       nix = "/nix/store/...-source/organist.ncl";
  #     };
  #   }
  # Result:
  #   {
  #     organist = {
  #       builders = import "/nix/store/...-source/builders.ncl",
  #       contracts = import "/nix/store/...-source/contracts.ncl",
  #       nix = import "/nix/store/...-source/organist.ncl",
  #     },
  #   }
  buildLockFile = contents:
    writeShellApplication {
      name = "regenerate-lockfile";
      text = ''
        cat > nickel.lock.ncl <${builtins.toFile "nickel.lock.ncl" (buildLockFileContents contents)}
      '';
    };
  # Flake app to generate nickel.lock.ncl file. Example usage:
  #   apps = {
  #     regenerate-lockfile = organist.lib.${system}.regenerateLockFileApp {
  #       organist = organist.lib.${system}.lockFileContents;
  #     };
  #   };
  regenerateLockFileApp = contents: {
    type = "app";
    program = lib.getExe (buildLockFile contents);
  };

  # Import a Nickel value produced by the Organist DSL
  importFromNickel = flakeInputs: system: baseDir: value: let
    type = builtins.typeOf value;
    isNickelDerivation = type: type == "nickelDerivation";
    importFromNickel_ = importFromNickel flakeInputs system baseDir;
  in
    if (type == "set")
    then
      (
        let
          organistType = value."${typeField}" or "";
        in
          if organistType == "module"
          then
            assert value ? config;
              importFromNickel_ value.config
          else if isNickelDerivation organistType
          then let
            prepared = prepareDerivation system (builtins.mapAttrs (_:
              importFromNickel_)
            value.nix_drv);
          in
            derivation prepared
          else if organistType == "nixString"
          then builtins.concatStringsSep "" (builtins.map importFromNickel_ value.fragments)
          else if organistType == "nixPath"
          then baseDir + "/${value.path}"
          else if organistType == "nixInput"
          then let
            attr_path = value.attr_path;
            possibleAttrPaths = [
              ([value.input] ++ attr_path)
              ([value.input "packages" system] ++ attr_path)
              ([value.input "legacyPackages" system] ++ attr_path)
            ];
            notFound = throw "Missing input \"${value.input}#${lib.strings.concatStringsSep "." attr_path}\"";
            chosenAttrPath =
              lib.findFirst
              (path: lib.hasAttrByPath path flakeInputs)
              notFound
              possibleAttrPaths;
          in
            lib.getAttrFromPath chosenAttrPath flakeInputs
          else if organistType == "nixPlaceholder"
          then builtins.placeholder value.output
          else if organistType == "nixToFile"
          then writeText value.name (importFromNickel_ value.text)
          else if organistType == "callNix"
          then let
            fileExpr = builtins.toFile "nickel-generated-expr" (importFromNickel_ value.function);
            importedArgs = importFromNickel_ value.args;
          in
            import fileExpr importedArgs
          else builtins.mapAttrs (_: importFromNickel_) value
      )
    else if (type == "list")
    then builtins.map importFromNickel_ value
    else value;

  # Call Nickel on a given Nickel expression with the inputs declared in it.
  # See importOrganist for details about the flakeInputs parameter.
  callNickel = {
    /*
    : [String]

    The command-line arguments to pass to `nickel export`
    */
    nickelArgs,
    /*
    : String

    The base path for resolving `organist.nix.import_file`
    */
    baseDir,
  }:
    runCommand "nickel-res.json" {
      __structuredAttrs = true;
      inherit nickelArgs;
    } ''
      ${nickel}/bin/nickel export --format json ''${nickelArgs[@]} > $out
    '';

  /*
  Import a Nickel expression as a Nix value.

  The result of the Nickel evaluation will be directly mapped to Nix values
  (through their JSON interface), with the exception of record containing the
  special `__organist_type` field which have a special treatment as per the
  `importFromNickel` function above.
  */
  importNickel = {
    /*
    : [String]

    Raw arguments passed to the `nickel export` command.
    This must at least contain the path to one Nickel file
    */
    nickelArgs,
    /*
    The path relative to which to resolve the `nix.import_file` calls.

    Can be left to its default value if `import_file` is not used.
    */
    baseDir ? "/non-existent-path-please-set-baseDir",
    /*
    The inputs to which `nix.import_nix` calls will be resolved.

    Can be left to its default value if `import_nix` is not used.
    */
    flakeInputs ? {
      nixpkgs = pkgs;
      organist = import organistSrc;
    },
  }: let
    nickelResult = callNickel {inherit nickelArgs baseDir;};
  in
    {rawNickel = nickelResult;}
    // (importFromNickel flakeInputs system baseDir (builtins.fromJSON
        (builtins.unsafeDiscardStringContext (builtins.readFile nickelResult))));

  /*
  Prepare an Organist project for consumption in Nix.
  */
  preprocessOrganist = {
    projectRoot,
    lockFileContents,
    nickelFile,
    flakeInputs,
  }
  : let
    sources = builtins.path {
      path = projectRoot;
      # TODO: filter .ncl files?
      # filter =
    };
    expectedLockfileContents = buildLockFileContents lockFileContents;

    paramsFile = pkgs.writers.writeJSON "params.json" {inherit system;};

    # Regenerate the lockfile to force it to match what we pass in through Nix
    nickel_source_root =
      runCommand "nickel-res.json" {
        inherit expectedLockfileContents;
        passAsFile = ["expectedLockfileContents"];
      }
      ''
        cp -r "${sources}" $out
        if [ -f $out/nickel.lock.ncl ]; then
          chmod +w $out $out/nickel.lock.ncl
        else
          chmod +w $out
        fi
        cp $expectedLockfileContentsPath $out/nickel.lock.ncl
      '';

    # The original flake inputs, but with an extra internal one containing the path to the lockfile
    # so that we can add it to the repository afterwards
    enrichedFlakeInputs =
      flakeInputs
      // {
        "%%organist_internal".nickelLock = "${nickel_source_root}/nickel.lock.ncl";
      };
  in {
    nickelArgs = [paramsFile "${nickel_source_root}/${nickelFile}" "--field" "config.flake"];
    baseDir = nickel_source_root;
    flakeInputs = enrichedFlakeInputs;
  };

  /*
  Import an Organist project into Nix.
  */
  importOrganist = {
    /*
    The desired contents of the `nickel.lock.ncl` file.
    */
    lockFileContents,
    /*
    The inputs of the flake, for resolving the `nix.import_nix` function.
    */
    flakeInputs,
    /*
    The root of the project
    */
    projectRoot,
    /*
    Path to the entrypoint, relative to the project root
    */
    nickelFile ? "project.ncl",
  }: let
    preprocessedExpression = preprocessOrganist {
      inherit nickelFile lockFileContents projectRoot flakeInputs;
    };
  in
    importNickel preprocessedExpression;
in {
  inherit
    importNickel
    importOrganist
    buildLockFile
    buildLockFileContents
    regenerateLockFileApp
    ;
}
