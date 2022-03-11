# nickel-nix

An experimental Nix toolkit to use nickel as a language for writing nix
packages, shells and more.

## Content

This repo is composed of a Nix library, a Nickel library and a flake which
provides the main entry point of `nickel-nix`, the Nix `importFromNcl` function.
This function takes a Nickel file and inputs to forward and produce a
derivation.

The Nickel library contain in-code documentation that can be leveraged by the
`nickel query` command. For example:

- `nickel query -f nix.ncl` will show the top-level documentation and the list of
    available symbols
- `nickel query -f nix.ncl lib.nix_string_hack` will show the documentation of a
    specific symbol, here `lib.nix_string_hack`.

### Examples

The `example/nix-shell` shows how to use `nickel-nix` to writer a simple `hello`
shell. More examples of varied Nix derivations are to come.
