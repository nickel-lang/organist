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
      callNickel = nickel-nix.packages.${system}.callNickel;
      nickelThing = callNickel {
        baseDir = ./.;
        nickelFile = ./nickel-dev-shell.ncl;
        flakeInputs = inputs;
      };
      nickelDerivation =
        builtins.derivation
        (
          builtins.fromJSON
          (
            builtins.readFile
            nickelThing
          ) // {inherit system;}
        );
    in rec {
      packages = rec {
        inherit nickelThing nickelDerivation;
        default = nickelDerivation;
      };
      devShells = {
        default = nickelDerivation;
      };
    });
}
