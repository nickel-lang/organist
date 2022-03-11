{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";

  nixConfig = {
    extra-substituters = [ "https://nickel.cachix.org" ];
    extra-trusted-public-keys = [ "nickel.cachix.org-1:ABoCOGpTJbAum7U6c+04VbjvLxG9f0gJP5kYihRRdQs=" ];
  };

  outputs = { self, nixpkgs, flake-utils, nickel-nix } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        importNcl = nickel-nix.packages.${system}.importNcl;
      in rec {
        devShell = devShells.withNickel;
        devShells =
          { withNix = import ./shell.nix { inherit pkgs; };
            withNickel = importNcl ./shell.ncl inputs;
            withNickelNixString = importNcl ./shell-nix-string.ncl inputs;
          };
      });
}
