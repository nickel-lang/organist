{
  description = "Nickel shim for Nix";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel.url = "github:tweag/nickel";

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
          nickel = nickel.packages.${system}.default;
        };
        packages.callNickel = pkgs.callPackage self.lib.callNickel {
          inherit system;
          nickel = nickel.packages.${system}.default;
        };
      }
  );
}
