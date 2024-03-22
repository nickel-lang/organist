{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;

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
    flake-compat,
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
        organist = "${self}/lib/organist.ncl";
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

    computedOutputs = outputsFromNickel ./. (inputs // {organist = self;}) {
      lockFileContents.organist = "./lib/organist.ncl";
    };
  in
    {
      templates.default = {
        path = ./templates/default;
        description = "A devshell using nickel.";
        welcomeText = ''
          You have just created an _Organist_-powered development shell.

          - Enter the environment with `nix develop`
          - Tweak it by modifying `project.ncl`

          _Hint_: To be able to leverage the Nickel language server for instant feedback on your configuration, run `nix run .#regenerate-lockfile` first.
        '';
      };
      flake.outputsFromNickel = outputsFromNickel;
    }
    // computedOutputs
    // flake-utils.lib.eachDefaultSystem (
      system: {
        lib = nixpkgs.legacyPackages.${system}.callPackage ./lib/lib.nix {
          organistSrc = self;
          nickel = inputs.nixpkgs.legacyPackages."${system}".nickel;
        };
      }
    );
}
