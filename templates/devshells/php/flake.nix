{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";

  nixConfig = {
    extra-substituters = [
      "https://tweag-nickel.cachix.org"
      "https://tweag-topiary.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="
      "tweag-topiary.cachix.org-1:8TKqya43LAfj4qNHnljLpuBnxAY/YwEBfzo3kzXxNY0="
    ];
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
