{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel/1.1.1";
  inputs.topiary.follows = "nickel/topiary";

  nixConfig = {
    extra-substituters = [
      "https://tweag-nickel.cachix.org"
      "https://tweag-topiary.cachix.org"
      "https://nickel-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="
      "tweag-topiary.cachix.org-1:8TKqya43LAfj4qNHnljLpuBnxAY/YwEBfzo3kzXxNY0="
      "nickel-nix.cachix.org-1:/Ziozgt3g0CfGwGS795wyjRa9ArE89s3tbz31S6xxFM="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel,
    topiary,
  } @ inputs:
    {
      templates = let
        inherit (nixpkgs) lib;
        brokenShells = ["javascript" "php" "python310"];
        filteredShells = (
          lib.filterAttrs
          (name: value: !(builtins.elem name brokenShells))
          (builtins.readDir ./templates/devshells)
        );
      in
        lib.mapAttrs'
        (
          name: value:
            lib.nameValuePair
            (name + "-devshell")
            {
              path = ./templates/devshells/${name};
              description = "A ${name} devshell using nickel.";
              welcomeText = ''
                You have created a ${name} devshell that is built using nickel!

                First run `nix run .#regenerate-lockfile` to fill `nickel.lock.ncl` with proper references.

                Then run `nix develop` to enter the dev shell.
              '';
            }
        )
        filteredShells;

      # Generate typical flake outputs from .ncl files in path for provided systems (default from flake-utils):
      #
      # apps.${system}.regenerate-lockfile generated from optional lockFileContents argument,
      #   defaulting to `nickel-nix` pointing to this flake
      # devShells.${system}.default generated from dev-shell.ncl
      # packages.${system}.default generated from package.ncl
      #
      # (to be extended with more features later)
      flake.outputsFromNickel = path: inputs: {
        systems ? flake-utils.lib.defaultSystems,
        lockFileContents ? {
          nickel-nix = "${./.}/lib/nix.ncl";
        },
      }:
        flake-utils.lib.eachSystem systems (system: let
          lib = self.lib.${system};
        in
          {
            apps.regenerate-lockfile = lib.regenerateLockFileApp lockFileContents;
          }
          // nixpkgs.lib.pipe path [
            builtins.readDir
            (nixpkgs.lib.mapAttrsToList (name: value:
              {
                "dev-shell.ncl" = nixpkgs.lib.nameValuePair "devShells" {
                  default = lib.importNcl path name inputs;
                };
                "package.ncl" = nixpkgs.lib.nameValuePair "packages" {
                  default = lib.importNcl path name inputs;
                };
              }
              .${name}
              or []))
            nixpkgs.lib.flatten
            nixpkgs.lib.listToAttrs
          ]);
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        lib = pkgs.callPackage ./lib/lib.nix {
          inherit system;
          nickel = inputs.nickel.packages."${system}".nickel-lang-cli;
        };
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        lib.importNcl = lib.importNcl;

        # Helper function that generates ugly contents for "nickel.lock.ncl", see buildLockFile.
        lib.buildLockFileContents = contents: let
          lib = pkgs.lib;
          getLinesOne = name: thing:
            if lib.isAttrs thing
            then
              [
                ((lib.optionalString (name != null) "${name} = ") + "{")
              ]
              ++ lib.mapAttrsToList getLinesOne thing
              ++ [
                ("}" + (lib.optionalString (name != null) ","))
              ]
            else [''${name} = import "${builtins.toString thing}",''];
        in
          lib.concatLines (lib.flatten (getLinesOne null contents));

        # A script that generates contents of "nickel.lock.ncl" file from a recursive attribute set of strings.
        # File contents is piped through topiary to make them pretty and check for correctnes
        # Example inputs:
        #   {
        #     nickel-nix = {
        #       builders = "/nix/store/...-source/builders.ncl";
        #       contracts = "/nix/store/...-source/contracts.ncl";
        #       nix = "/nix/store/...-source/nix.ncl";
        #     };
        #   }
        # Result:
        #   {
        #     nickel-nix = {
        #       builders = import "/nix/store/...-source/builders.ncl",
        #       contracts = import "/nix/store/...-source/contracts.ncl",
        #       nix = import "/nix/store/...-source/nix.ncl",
        #     },
        #   }
        lib.buildLockFile = contents:
          pkgs.writeShellApplication {
            name = "regenerate-lockfile";
            text = ''
              ${pkgs.lib.getExe topiary.packages.${system}.default} -l nickel > nickel.lock.ncl <<EOF
              ${self.lib.${system}.buildLockFileContents contents}
              EOF
            '';
          };

        # Flake app to generate nickel.lock.ncl file. Example usage:
        #   apps = {
        #     regenerate-lockfile = nickel-nix.lib.${system}.regenerateLockFileApp {
        #       nickel-nix = nickel-nix.lib.${system}.lockFileContents;
        #     };
        #   };
        lib.regenerateLockFileApp = contents: {
          type = "app";
          program = pkgs.lib.getExe (self.lib.${system}.buildLockFile contents);
        };

        apps.tests = let
          mkTest = {
            name,
            script,
          }: let
            test = pkgs.writeShellApplication {
              inherit name;
              text = ''
                set -xeuo pipefail
                WORKDIR=$(mktemp -d)
                function clean() {
                  rm -rf "''${WORKDIR}"
                }
                trap clean EXIT
                cd "''${WORKDIR}"

                ${script}
              '';
            };
          in {
            type = "app";
            program = "${pkgs.lib.getExe test}";
          };
        in {
          templates = pkgs.lib.flip pkgs.lib.mapAttrs self.templates (
            name: _:
              mkTest {
                name = "test devshell ${name}";
                script = ''
                  nix flake new --template path:${./.}#${name} example --accept-flake-config

                  pushd ./example
                  # We test against the local version of `nickel-nix`, not the one in main (hence the --override-input).
                  nix flake lock --override-input nickel-nix path:${./.} --accept-flake-config
                  nix run .#regenerate-lockfile --accept-flake-config
                  nix develop --accept-flake-config --print-build-logs < /dev/null
                  popd
                '';
              }
          );
          examples = pkgs.lib.flip pkgs.lib.mapAttrs (builtins.readDir ./examples) (
            name: _:
              mkTest {
                name = "test ${name}";
                script = ''
                  cp -r ${./.}/examples/${name} ./${name}
                  chmod -R u+w ./${name}
                  cd ./${name}
                  nix flake lock --override-input nickel-nix path:${./.}
                  nix run .#regenerate-lockfile --accept-flake-config
                  nix build --accept-flake-config
                '';
              }
          );
        };

        devShells.default = pkgs.mkShell {
          packages = [
            inputs.nickel.packages."${system}".default
          ];
        };
      }
    );
}
