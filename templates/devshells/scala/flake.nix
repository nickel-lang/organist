{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";

  nixConfig = {
    extra-substituters = ["https://nickel-nix.cachix.org"];
    extra-trusted-public-keys = ["nickel-nix.cachix.org-1:/Ziozgt3g0CfGwGS795wyjRa9ArE89s3tbz31S6xxFM="];
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nickel-nix,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nickel-nix.lib.${system}) importNcl regenerateLockFileApp;
      nickelDerivation = importNcl ./. "dev-shell.ncl" inputs;
      lockFileContents = {
        nickel-nix = nickel-nix.lib.${system}.lockFileContents;
      };
    in rec {
      devShells = {
        default = nickelDerivation;
      };
      apps = {
        regenerate-lockfile = regenerateLockFileApp lockFileContents;
      };
    });
}
