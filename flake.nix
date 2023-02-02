{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel/master";

  nixConfig = {
    extra-substituters = ["https://tweag-nickel.cachix.org"];
    extra-trusted-public-keys = ["tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel,
  } @ inputs:
    {
      templates =
        (
          let
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

                    Run `nix develop --impure` to enter the dev shell.
                  '';
                }
            )
            filteredShells
        )
        // {};
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        lib = import ./lib.nix;
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        lib.importNcl = pkgs.callPackage lib.importNcl {
          inherit system;
          nickel = inputs.nickel.packages."${system}".nickel;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            inputs.nickel.packages."${system}".nickel
          ];
        };
      }
    );
}
