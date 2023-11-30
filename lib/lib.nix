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
  importFromNickel = flakeInputs: system: baseDir: importFromNickelWithHashConsing flakeInputs system baseDir {};

  importFromNickelWithHashConsing = flakeInputs: system: baseDir: valueCache: value: let
    type = builtins.typeOf value;
    isNickelDerivation = type: type == "nickelDerivation";
    importFromNickel_ = importFromNickelWithHashConsing flakeInputs system baseDir;
  in
    if (type == "set")
    then
      (
        let
          organistType = value."${typeField}" or "";
        in
          if value ? value_hash
          then
            assert (valueCache ? ${value.value_hash});
            {
              inherit valueCache;
              value = valueCache.${value.value_hash};
            }
          else if isNickelDerivation organistType
          then let
            drvArgsWithCache = importFromNickel_ valueCache value.nix_drv;
          in let
            prepared = prepareDerivation system drvArgsWithCache.value;
          in {
            valueCache = drvArgsWithCache.valueCache;
            value = builtins.trace (builtins.typeOf prepared) builtins.derivation prepared;
          }
          else if organistType == "nixString"
          then let
            importedElements =
              builtins.foldl'
              (acc: element: let
                valWithCache = importFromNickel_ acc.valueCache element;
              in {
                valueCache = valWithCache.valueCache;
                value = acc.value + valWithCache.value;
              })
              {
                valueCache = valueCache;
                value = "";
              }
              value.fragments;
          in
            importedElements
          # then builtins.concatStringsSep "" (builtins.map importFromNickel_ value.fragments)
          else if organistType == "nixPath"
          then {
            inherit valueCache;
            value = baseDir + "/${value.path}";
          }
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
          in {
            inherit valueCache;
            value = lib.getAttrFromPath chosenAttrPath flakeInputs;
          }
          else if organistType == "nixBuiltinCall"
          then let
            builtin_name = value.name;
            builtin_arg = value.arg;
          in
            let argWithCache = importFromNickel_ valueCache builtin_arg; in
            {
              valueCache = argWithCache.valueCache;
              value = builtins.${builtin_name} argWithCache.value;
            }
          else if organistType == "nixToFile"
          then let textWithCache = importFromNickel_ valueCache value.text; in {
            valueCache = textWithCache.valueCache;
            value = writeText value.name textWithCache.value;
          }
          else if organistType == "callNix"
          then let
            functionWithCache = importFromNickel_ valueCache value.function;
            argsWithCache = importFromNickel_ functionWithCache.valueCache value.args;
            fileExpr = builtins.toFile "nickel-generated-expr" functionWithCache.value;
          in
          {
            valueCache = argsWithCache.valueCache;
            value = import fileExpr argsWithCache.value;
          }
          else
          lib.foldlAttrs
            (acc: key: val: let
              valWithCache = importFromNickel_ acc.valueCache val;
            in {
              valueCache = valWithCache.valueCache;
              value = acc.value // {${key} = valWithCache.value;};
            })
            {
              valueCache = valueCache;
              value = {};
            }
            value
      )
    # else if (type == "list")
    # then builtins.map importFromNickel_ value
    else { valueCache = valueCache; value = value; };

  # Call Nickel on a given Nickel expression with the inputs declared in it.
  # See importNcl for details about the flakeInputs parameter.
  callNickel = {
    nickelFile,
    flakeInputs,
    baseDir,
    lockFileContents,
  }: let
    sources = builtins.path {
      path = baseDir;
      # TODO: filter .ncl files
      # filter =
    };

    lockfilePath = "${sources}/nickel.lock.ncl";
    expectedLockfileContents = buildLockFileContents lockFileContents;
    needNewLockfile = !builtins.pathExists lockfilePath || (builtins.readFile lockfilePath) != expectedLockfileContents;

    nickelWithImports = src: ''
      let params = {
        system = "${system}",
      }
      in
      let organist = (import "${src}/nickel.lock.ncl").organist in

      let nickel_expr | (organist.OrganistExpression & {..}) =
        import "${src}/${nickelFile}" in

      organist.lib.hash_consing.hashCons (nickel_expr & params)
    '';
  in
    runCommand "nickel-res.json" {
      # If expectedLockfileContents references current flake in context, propagate it even if we don't need it.
      inherit expectedLockfileContents;
      passAsFile = ["expectedLockfileContents"];
    } (
      if needNewLockfile
      then
        lib.warn ''
          Lockfile contents are outdated. Please run "nix run .#regenerate-lockfile" to update them.
        ''
        ''
          cp -r "${sources}" sources
          if [ -f sources/nickel.lock.ncl ]; then
            chmod +w sources sources/nickel.lock.ncl
          else
            chmod +w sources
          fi
          cp $expectedLockfileContentsPath sources/nickel.lock.ncl
          cat > eval.ncl <<EOF
          ${nickelWithImports "sources"}
          EOF
          ${nickel}/bin/nickel export eval.ncl > $out
        ''
      else ''
        cat > eval.ncl <<EOF
        ${nickelWithImports sources}
        EOF
        ${nickel}/bin/nickel export eval.ncl > $out
      ''
    );

  # Import a Nickel expression as a Nix value. flakeInputs are where the packages
  # passed to the Nickel expression are taken from. If the Nickel expression
  # declares an input hello from input "nixpkgs", then flakeInputs must have an
  # attribute "nixpkgs" with a package "hello".
  importNcl = {
    baseDir,
    nickelFile ? "project.ncl",
    flakeInputs ? {
      nixpkgs = pkgs;
      organist = import organistSrc;
    },
    lockFileContents ? {
      organist = "${organistSrc}/lib/organist.ncl";
    },
  }: let
    nickelResult = callNickel {
      inherit nickelFile baseDir flakeInputs lockFileContents;
    };
  in
    {rawNickel = nickelResult;}
    // (importFromNickel flakeInputs system baseDir (builtins.fromJSON
        (builtins.unsafeDiscardStringContext (builtins.readFile nickelResult))));
in {
  inherit
    importNcl
    buildLockFile
    buildLockFileContents
    regenerateLockFileApp
    ;
}
