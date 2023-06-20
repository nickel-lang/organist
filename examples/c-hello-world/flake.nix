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
      importNcl = nickel-nix.lib.${system}.importNcl;
    in {
      # we want hello.c to be part of the source of the hello package, but we
      # don't have yet a way to easily import plain files into the Nickel
      # world. This is a temporary hack: we wrap hello.co as a stub package
      # and pass it as any other input to the Nickel part.
      packages.default = importNcl ./. "hello.ncl" inputs;

      apps = {
        regenerate-lockfile = {
          type = "app";
          program = pkgs.lib.getExe (nickel-nix.lib.${system}.buildLockFile {
            nickel-nix = nickel-nix.lib.${system}.lockFileContents;
          });
        };
      };
    });
}
