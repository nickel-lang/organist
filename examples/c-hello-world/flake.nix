{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";
  inputs.nickel-nix.url = "/home/yago/Pro/Tweag/projects/nickel/nickel-nix";
nixConfig = {
    extra-substituters = [ "https://nickel.cachix.org" ];
    extra-trusted-public-keys = [ "nickel.cachix.org-1:ABoCOGpTJbAum7U6c+04VbjvLxG9f0gJP5kYihRRdQs=" ];
  };

  outputs = { self, nixpkgs, flake-utils, nickel-nix } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        importNcl = nickel-nix.packages.${system}.importNcl;
      in {
        # we want hello.c to be part of the source of the hello package, but we
        # don't have yet a way to easily import plain files into the Nickel
        # world. This is a temporary hack: we wrap hello.co as a stub package
        # and pass it as any other input to the Nickel part.
        packages.default = importNcl ./. ./hello.ncl inputs;
      });
}
