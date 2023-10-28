{
  derivation
    | doc m%"
      Low-level interface for interfacing with Nix values and constructing
      derivations from Nickel.
    "%
    = import "derivation.ncl",
  builders
    | doc m%"
      Library of standard builders used for writing derivations.
    "%
    = import "builders.ncl",
  shells
    | doc m%"
      Library of standard development environments.
    "%
    = import "shells.ncl",
  builtins
    | doc m%"
      Wrapper around Nix primops and built-in language features.
    "%
    = import "builtins.ncl",
  utils
    | doc m%"
      Miscellaneous helper functions.
    "%
    = import "utils.ncl",

  import_nix = builtins.import_nix,
}
