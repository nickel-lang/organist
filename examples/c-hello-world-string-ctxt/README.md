# C hello world

This example builds a simple C hello wolrd program through nickel-nix, using
Nickel's symbolic strings to emulate Nix string context for automatically
filling the `dependencies` field.

## Usage

```console
$ nix build --impure
$ ./result/bin/hello
Hello, world!
```
