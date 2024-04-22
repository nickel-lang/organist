{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.organist.url = "github:nickel-lang/organist";

  nixConfig = {
    extra-substituters = ["https://organist.cachix.org" "https://nix-community.cachix.org"];
    extra-trusted-public-keys = ["organist.cachix.org-1:GB9gOx3rbGl7YEh6DwOscD1+E/Gc5ZCnzqwObNH2Faw=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };

  outputs = {organist, ...} @ inputs:
    organist.flake.outputsFromNickel ./. inputs {};
}
