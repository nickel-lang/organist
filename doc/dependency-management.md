# Managing your dependencies with Organist

Organist can be used to manage your development dependencies, and the whole environment.

## Getting started

After running `nix flake init`, you should end-up with a `project.ncl` looking like:

```nickel
let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  shells = organist.shells.Bash,

  shells.build = {
    packages = {},
  },

  shells.dev = {
    packages.hello = organist.lib.import_nix "nixpkgs#hello",
  },
} | organist.contracts.NixelExpression
```

This defines two variants of the shell: `build` and `dev`, both of which inherit from `organist.shells.Bash` (more precisely, `build` inherits from `organist.shells.Bash.build` and `dev` inherits from `organist.shells.Bash.dev`).

You can enter the `dev` shell by running `nix develop` or `nix develop .#dev` and the build shell with `nix develop .#build`.

## Customizing the base shell

You can use a different base for your shell by replacing `shells = organist.shells.Bash` but something else, like `shells = organist.shells.Rust`.
You can even depend on multiple ones at the same time with

```ncl
  shells = organist.shells.Nickel,
  shells = organist.shells.Rust,
```

The merging system will take care of combining their definitions.

## Adding new Nix dependencies

Beyond these predefined generic environments, you can also customize the shells by adding some extra dependencies to them in the `packages` attribute.

Most of the time, these packages will come from `nixpkgs` through the `nix_import` function.

You can find the packages you need on https://search.nixos.org.

## Setting environment variables

The shell options also take an `env` setting that can be used to declare arbitrary environment variables to be set. For instance setting

```nickel
shells.dev.env.FASTBUILD = 1,
```

will make sure that the `dev` shells will have the `FASTBUILD` environment variable set to `1`.

These variables can also refer to Nix inputs by using the special `nix-s%" "%` [symbolic string].
For instance, if you want your dev environment to use `jemalloc` as its `malloc` implementation, you can hook it with:

```nickel
shells.build.env.LD_PRELOAD = nix-s%"%{inputs.nixpkgs.jemalloc}/lib/libjemalloc.so}"%
```

[symbolic strings]: https://nickel-lang.org/user-manual/syntax#symbolic-strings
