{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel-nix.url = "path:../../";

  nixConfig = {
    extra-substituters = ["https://nickel.cachix.org"];
    extra-trusted-public-keys = ["nickel.cachix.org-1:ABoCOGpTJbAum7U6c+04VbjvLxG9f0gJP5kYihRRdQs="];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel-nix,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      importNcl = nickel-nix.packages.${system}.importNcl;
      nakedStdenv = importNcl ./. ./naked-stdenv.ncl inputs;
      nickelDerivation =
        importNcl ./. ./nickel-dev-shell.ncl
        (
          inputs
          // {
            myInputs.packages.${system} = {inherit nakedStdenv;};
          }
        );
    in rec {
      packages = {
        default = nakedStdenv;
      };
      devShells = {
        default = nickelDerivation;
      };
    });
}
