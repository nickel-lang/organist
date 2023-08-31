{
  description = "A basic flake with a shell";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.organist.url = "github:nickel-lang/organist";

  nixConfig = {
    extra-substituters = ["https://nickel-nix.cachix.org"];
    extra-trusted-public-keys = ["nickel-nix.cachix.org-1:/Ziozgt3g0CfGwGS795wyjRa9ArE89s3tbz31S6xxFM="];
  };

  outputs = {organist, ...} @ inputs:
    organist.flake.outputsFromNickel ./. inputs {};
}
