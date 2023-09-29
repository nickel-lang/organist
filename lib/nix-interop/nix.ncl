{
  derivation = import "derivation.ncl",
  builders = import "builders.ncl",
  shells = import "shells.ncl",
  builtins = import "builtins.ncl",

  import_nix = builtins.import_nix,
}
