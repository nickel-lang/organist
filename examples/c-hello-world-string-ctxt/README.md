# C hello world

This example builds a simple C hello wolrd program through nickel-nix, using
Nickel's symbolic strings to emulate Nix string context for automatically
filling the `dependencies` field.

## Usage

```console
$ nix build --impure
[..]
$ ./result/bin/hello
Hello, world!
```

If you're using this example in a standalone way, outside of the `nickel-nix`
repository, comment the following line inside `flake.nix`:

```diff
-  inputs.nickel-nix.url = "path:../../";
+  # inputs.nickel-nix.url = "path:../../";
```

and uncomment the line just before:

```diff
-  # inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";
+  inputs.nickel-nix.url = "github:nickel-lang/nickel-nix";
```
