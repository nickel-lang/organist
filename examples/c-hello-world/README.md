# C hello world

This example builds a simple C hello wolrd program through nickel-nix.

## Usage

```console
$ nix build --impure
$ ./result/bin/hello
Hello, world!
```

## Additional context

This example uses the special `sources` input type to import the `hello.c` file.
Moreover, as opposed to idiomatic Nix, we have to repeat `bash`, `coreutils`,
`gcc` and `hello` in the `dependencies` field.

Those issues are alleviated thanks to a Nickel feature called symbolic string.
See the [C hello world with string
context](../c-hello-world-string-ctxt/README.md) example for more details.
