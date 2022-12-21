# nickel-nix

An experimental Nix toolkit to use Nickel as a language for writing nix
packages, shells and more.

## Content

This repo is composed of a Nix library, a Nickel library and a flake which
provides the main entry point of `nickel-nix`, the Nix `importFromNcl` function.
This function takes the current directory, a Nickel file and inputs to forward
and produces a derivation.

The Nickel library contains in-code documentation that can be leveraged by the
`nickel query` command. For example:

- `nickel query -f nix.ncl` will show the top-level documentation and the list of
    available symbols
- `nickel query -f nix.ncl lib.import_file` will show the documentation of a
    specific symbol, here `import_file`.

## Examples

`examples/c-hello-world` and its variations build a simple hello world
program in C.

The previous example of a shell based on `mkShell` has been removed. Nickel-nix
takes the route of re-implementing a modular devshell framework in pure Nickel,
relying solely on Nix for `derivation`. An example of a such basic development
shell is planned in a coming pull request.

More examples of varied derivations are to come.
