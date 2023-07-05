{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";

  nixConfig = {
    extra-substituters = ["https://nickel-nix.cachix.org"];
    extra-trusted-public-keys = ["nickel-nix.cachix.org-1:/Ziozgt3g0CfGwGS795wyjRa9ArE89s3tbz31S6xxFM="];
  };

  outputs = {nickel-nix, ...} @ inputs:
    nickel-nix.flake.outputsFromNickel ./. inputs {};
}
