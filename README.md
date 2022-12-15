# Nickel-nix

An experimental Nix toolkit to use [Nickel](https://github.com/tweag/nickel) as a
language for writing nix packages, shells and more.

**Caution**: `nickel-nix` is not a full-fledged Nix integration. It is currently
missing several basic features. `nickel-nix` is intended to be a
proof-of-concept for writing a Nix derivation using Nickel at the moment,
without requiring new features either in Nix or in Nickel. The future of the
integration of Nix and Nickel will most probably involve deeper changes to the
two projects, and hopefully lead to a more featureful and ergonomic solution.

## Content

This repo is composed of a Nix library, a Nickel library and a flake which
provides the main entry point of `nickel-nix`, the Nix `importFromNcl` function.
This function takes the current directory, a Nickel file and inputs to forward
and produces a derivation.

The Nickel library contains in-code documentation that can be leveraged by the
`nickel query` command. For example:

- `nickel query -f nix.ncl` will show the top-level documentation and the list of
    available symbols
- `nickel query -f nix.ncl lib.nix_string_hack` will show the documentation of a
    specific symbol, here `lib.nix_string_hack`.

## Examples

`example/nix-shell` shows how to use `nickel-nix` to write a simple `hello`
shell. `examples/c-hello-world` and its variations builds a simple hello world
program in C. More examples of varied Nix derivations are to come.
