# Managing your dependencies with Nixel

Nixel can be used to manage your development dependencies, and the whole environment.

## Getting started

After running `nix flake init`, you should end-up with a `project.ncl` looking like:

```nickel
let Nixel = import ".nickel-nix/lock.ncl" in
let inputs = Nixel.nix.import_flake "." in
{
  shells = Nixel.shells.Nickel,

  shells.build = {
    packages = [],
  },
  shells.dev = {
    packages = [],
  },

  # More stuff
}
```

This defines two variants of the shell: `build` and `dev`, both of which inherit from `Nixel.shells.Nickel` (more precisely, `build` inherits from `Nixel.shells.Nickel.build` and `dev` inherits from `Nixel.shells.Nickel.dev`).

You can enter the `dev` shell by running `nix develop` or `nix develop .#dev` and the build shell with `nix develop .#build`.

## Customizing the base shell

You can use a different base for your shell by replacing `shells = Nixel.shells.Nickel` byt something else, liks `shells = Nixel.shells.Rust`.
You can even depend on multiple ones at the same time with

```ncl
  shells = Nixel.shells.Nickel,
  shells = Nixel.shells.Rust,
```

(the merging system taking care of combining their definitions)

## Adding new Nix dependencies

Beyond these predefined generic environments, you can also customize the shells by adding some extra dependencies to them in the `packages` attribute.

Most of the time, these dependencies will come from `inputs.nixpkgs`, the main Nix package collection.

```nickel
shell.build.packages = [ inputs.nixpkgs.hello, inputs.nixpkgs.haskellPackages.pandoc ],
```

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

XXX: This is a crappy example. Need to find a better one.

[symbolic strings]: https://nickel-lang.org/user-manual/syntax#symbolic-strings
