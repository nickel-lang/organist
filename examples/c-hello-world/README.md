# C hello world

This example builds a simple C hello world program through organist.

## Usage

```console
$ nix run .#regenerate-lockfile
$ nix build --impure
[..]
$ ./result/bin/hello
Hello, world!
```

If you're using this example in a standalone way, outside of the `organist`
repository, comment the following line inside `flake.nix`:

```diff
-  inputs.organist.url = "path:../../";
+  # inputs.organist.url = "path:../../";
```

and uncomment the line just before:

```diff
-  # inputs.organist.url = "github:nickel-lang/organist";
+  inputs.organist.url = "github:nickel-lang/organist";
```

## Additional context

This example uses the special `sources` input type to import the `hello.c` file.
Moreover, as opposed to idiomatic Nix, we have to repeat `bash`, `coreutils`,
`gcc` and `hello` in the `dependencies` field.

Those issues are alleviated thanks to a Nickel feature called symbolic string.
See the [C hello world with string
context](../c-hello-world-string-ctxt/README.md) example for more details.
