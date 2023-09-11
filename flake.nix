{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel";

  nixConfig = {
    extra-substituters = [
      "https://organist.cachix.org"
    ];
    extra-trusted-public-keys = [
      "organist.cachix.org-1:GB9gOx3rbGl7YEh6DwOscD1+E/Gc5ZCnzqwObNH2Faw="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel,
  } @ inputs:
    {
      templates.default = {
        path = ./templates/default;
        description = "A devshell using nickel.";
        welcomeText = ''
          You have created a devshell that is built using nickel!

          You can run `nix develop` to enter the dev shell.
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
            nickelOutputs = lib.importNcl path "project.ncl" inputs lockFileContents;
            packages.default = nickelOutputs.packages.default or {};
            devShells = nickelOutputs.shells or {};
          });
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        lib = pkgs.callPackage ./lib/lib.nix {
          flakeRoot = self.outPath;
          nickel = inputs.nickel.packages."${system}".nickel-lang-cli;
        };
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        inherit lib;

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

        checks.nickel-format =
          pkgs.runCommand "check-nickel-format" {
            buildInputs = [
              inputs.nickel.packages.${system}.nickel-lang-cli
            ];
          } ''
            cd ${self}
            failed=""
            for f in $(find . -name future -prune -or -name '*.ncl' -print); do
              if ! diff -u "$f" <(nickel format -f "$f"); then
                failed="$failed $f"
              fi
            done
            if [ "$failed" != "" ]; then
              echo "Following files need to be formatted: $failed"
              exit 1
            fi
            touch $out
          '';
      }
    );
}
