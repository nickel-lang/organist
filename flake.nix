{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

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
  } @ inputs: let
    # Generate typical flake outputs from .ncl files in path for provided systems (default from flake-utils):
    #
    # apps.${system}.regenerate-lockfile generated from optional lockFileContents argument,
    #   defaulting to `organist` pointing to this flake
    # devShells.${system} and packages.${system} generated from project.ncl
    #
    # (to be extended with more features later)
    outputsFromNickel = baseDir: flakeInputs: {
      systems ? flake-utils.lib.defaultSystems,
      lockFileContents ? {
        organist = "${self}/lib/nix.ncl";
      },
    }:
      flake-utils.lib.eachSystem systems (system: let
        lib = self.lib.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        nickelOutputs = lib.importNcl {
          inherit baseDir flakeInputs lockFileContents;
        };
      in
        # Can't do just `{inherit nickelOutputs;} // nickelOutputs.flake` because of infinite recursion over self
        pkgs.lib.optionalAttrs (builtins.readDir baseDir ? "project.ncl") {
          inherit nickelOutputs;
          packages = nickelOutputs.packages or {} // nickelOutputs.flake.packages or {};
          checks = nickelOutputs.flake.checks or {};
          # Can't define this app in Nickel, yet
          apps =
            {
              regenerate-lockfile = lib.regenerateLockFileApp lockFileContents;
            }
            // nickelOutputs.flake.apps or {};
          # We can't just copy `shells` to `flake.devShells` in the contract
          # because of a bug in Nickel: https://github.com/tweag/nickel/issues/1630
          devShells = nickelOutputs.shells or {} // nickelOutputs.flake.devShells or {};
        });

    computedOutputs = outputsFromNickel ./. inputs {
      lockFileContents.organist = "./lib/nix.ncl";
    };
  in
    {
      templates.default = {
        path = ./templates/default;
        description = "A devshell using nickel.";
        welcomeText = ''
          You have created a devshell that is built using nickel!

          You can run `nix develop` to enter the dev shell.
        '';
      };
      flake.outputsFromNickel = outputsFromNickel;
    }
    // computedOutputs
    // flake-utils.lib.eachDefaultSystem (
      system: let
        lib = pkgs.callPackage ./lib/lib.nix {
          organistSrc = self;
        };
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        inherit lib;

        checks =
          computedOutputs.checks.${system}
          // {
            alejandra = pkgs.runCommand "check-alejandra" {} ''
              ${pkgs.lib.getExe pkgs.alejandra} --check ${self}
              touch $out
            '';

            nickel-format =
              pkgs.runCommand "check-nickel-format" {
                buildInputs = [
                  pkgs.nickel
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
          };
      }
    );
}
