{
  nickel-nix = {
    builders = import "../../../builders.ncl",
    contracts = import "../../../contracts.ncl",
    naked-stdenv = import "../../../naked-stdenv.ncl",
    nix = import "../../../nix.ncl",
  },
}
