{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel";
  inputs.topiary.follows = "nickel/topiary";

  nixConfig = {
    extra-substituters = [
      "https://tweag-nickel.cachix.org"
      "https://tweag-topiary.cachix.org"
      "https://organist.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="
      "tweag-topiary.cachix.org-1:8TKqya43LAfj4qNHnljLpuBnxAY/YwEBfzo3kzXxNY0="
      "organist.cachix.org-1:GB9gOx3rbGl7YEh6DwOscD1+E/Gc5ZCnzqwObNH2Faw="
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
      templates.default = {
        path = ./templates/default;
        description = "A devshell using nickel.";
        welcomeText = ''
          You have created a devshell that is built using nickel!

          First run `nix run .#regenerate-lockfile` to fill `nickel.lock.ncl` with proper references.

          Then run `nix develop` to enter the dev shell.
        '';
      };

      # Generate typical flake outputs from .ncl files in path for provided systems (default from flake-utils):
      #
      # apps.${system}.regenerate-lockfile generated from optional lockFileContents argument,
      #   defaulting to `organist` pointing to this flake
      # devShells.${system} and packages.${system} generated from project.ncl
      #
      # (to be extended with more features later)
      flake.outputsFromNickel = path: inputs: {
        systems ? flake-utils.lib.defaultSystems,
        lockFileContents ? {
          organist = "${self}/lib/nix.ncl";
        },
      }:
        flake-utils.lib.eachSystem systems (system: let
          lib = self.lib.${system};
          pkgs = nixpkgs.legacyPackages.${system};
        in
          {
            apps.regenerate-lockfile = lib.regenerateLockFileApp lockFileContents;
          }
          // pkgs.lib.optionalAttrs (builtins.readDir path ? "project.ncl") rec {
            nickelOutputs = lib.importNcl path "project.ncl" inputs;
            packages.default = nickelOutputs.packages.default or {};
            devShells = nickelOutputs.shells or {};
          });
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        lib = pkgs.callPackage ./lib/lib.nix {
          inherit system;
          flakeRoot = self.outPath;
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
        #     organist = {
        #       builders = "/nix/store/...-source/builders.ncl";
        #       contracts = "/nix/store/...-source/contracts.ncl";
        #       nix = "/nix/store/...-source/nix.ncl";
        #     };
        #   }
        # Result:
        #   {
        #     organist = {
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
        #     regenerate-lockfile = organist.lib.${system}.regenerateLockFileApp {
        #       organist = organist.lib.${system}.lockFileContents;
        #     };
        #   };
        lib.regenerateLockFileApp = contents: {
          type = "app";
          program = pkgs.lib.getExe (self.lib.${system}.buildLockFile contents);
        };

        apps.run-test = let
          testScript = pkgs.writeShellApplication {
            name = "test-templates";
            runtimeInputs = [
              inputs.nickel.packages."${system}".nickel-lang-cli
              pkgs.parallel
              pkgs.gnused
            ];
            text = builtins.readFile ./run-test.sh;
          };
        in {
          type = "app";
          program = pkgs.lib.getExe testScript;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            inputs.nickel.packages."${system}".default
            pkgs.parallel
            pkgs.alejandra
          ];
        };

        checks.alejandra = pkgs.runCommand "check-alejandra" {} ''
          ${pkgs.lib.getExe pkgs.alejandra} --check ${self}
          touch $out
        '';
      }
    );
}
