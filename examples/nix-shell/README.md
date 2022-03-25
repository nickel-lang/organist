# Nickel shell

Example of using `nickel-nix` to write a simple shell in Nickel.

## Usage

```
$ nix develop --impure
[..]
Hello, world!
```

Because of the way the inputs are transmitted between Nix and Nickel, Nix can't
currently assess that evaluation is pure (which it is indeed). Hence, a current
limitation is that **you must use --impure when evaluating this flake**.

## Description

The [flake](./flake.nix) calls "Nickel expression" a Nickel file (ex:
`shell.ncl`) that will eventually produce a derivation. The Nickel expression
has a structure similar to flake: it is a record that define an `inputs` field
to specify its dependencies and an `output` field that is a function producing
the data required to build the derivation. This structure is not imposed by
Nickel or Nix, but an opiniated choice made by `nickel-nix`.

There are three different shell definition in this directory:
 - `shell.nix`: the standard Nix version of an hello shell
 - `shell.ncl`: the Nickel version of an hello shell
 - `shell-nix-string.ncl`: A variation demonstrating how to preserve Nix string
     contexts when writing a Nickel expression, even if not strictly required in
     for the hello shell.


