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
    lib = import ./lib.nix;
  } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.importNcl = pkgs.callPackage self.lib.importNcl {
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
