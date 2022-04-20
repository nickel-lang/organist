# Nickel shell

Example of using `nickel-nix` to write a simple shell in Nickel.

## Usage

```shell
$ nix develop --impure
[..]
Hello, world!
```

Because of the way the inputs are transmitted between Nix and Nickel, Nix can't
currently assess that evaluation is pure (which it is indeed). Hence, a current
limitation is that **you must use --impure when evaluating this flake**.

## Description

In this repository, a "Nickel expression" is a Nickel file (ex: `shell.ncl`)
that will eventually produce a derivation. The Nickel expression has a structure
similar to flake: it is a record that defines an `inputs` field to specify its
dependencies and an `output` field that is a function producing the data
required to build the derivation. This structure is not imposed by Nickel nor by
Nix, but an opiniated choice made by `nickel-nix`.

There are three different valid shell definitions in this directory:

- `shell.nix`: the standard Nix version of an `hello` shell
- `shell.ncl`: the Nickel version of an `hello` shell
- `shell-nix-string.ncl`: A variant demonstrating how to preserve Nix string
   contexts when writing a Nickel expression, even if not strictly required in
   for the hello shell.

There are two failing shell definitions to illustrate the difference of behavior
in error reporting between Nix and Nickel for basic type errors:

- `shell-type-error.nix`: a variant of `shell.nix` where `packages` was switched
    from a list to a string.
- `shell-type-error.ncl`: a variant of `shell.ncl` where `packages` was switched
    from a list to a string.
