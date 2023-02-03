# Nickel-nix

An experimental Nix toolkit to use
[Nickel](https://github.com/tweag/nickel) as a language for writing nix
packages, shells and more.

**Caution**: `nickel-nix` is not a full-fledged Nix integration. It is
currently missing several basic features. `nickel-nix` is intended to be a
proof-of-concept for writing a Nix derivation using Nickel at the moment,
without requiring new features either in Nix or in Nickel. The future
of the integration of Nix and Nickel will most probably involve deeper
changes to the two projects, and hopefully lead to a more featureful
and ergonomic solution.

# How to use

We currently provide a few basics development environment for some languages.
You need Nix with flakes enabled to use Nickel-nix:

You can list available development shell templates by running:

```shell
nix flake show github:nickel-lang/nickel-nix
```

The following example copies the rust devshell and enters the development
environment.

```shell
$ mkdir my_project
$ cd my_project
$ nix flake init -t github:nickel-lang/nickel-nix#rust-devshell
$ nix develop --impure
```

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
