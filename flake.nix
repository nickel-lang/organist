{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel/master";

  nixConfig = {
    extra-substituters = [ "https://tweag-nickel.cachix.org" ];
    extra-trusted-public-keys = [ "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA=" ];
  };

  outputs = { self, nixpkgs, flake-utils, nickel } @ inputs:
  {
    templates = {
      rust = {
        path = ./templates/rust-dev-shell;
        description = "A rust dev shell using nickel.";
      };
    };
  } // flake-utils.lib.eachDefaultSystem (system:
      let
        lib = import ./lib.nix;
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
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
