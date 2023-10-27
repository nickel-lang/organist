# Organist

_Control all your tooling from a single console_

Managing a project's development environment involves configuring a lot of tools and occasionally getting to communicate with each other: one (or several) package managers, a CI system, a service manager (to run that local postgresql database without which you can't test anything), custom utility scripts that end up spawning everywhere, etc.
Organist aims at being your main entrypoint for managaing all these different tools, so that you can get:

1. A unified configuration framework for all of these
2. A powerful and ergonomic language to allow you to easily abstract over these configurations, with discoverability and early error reporting

Organist currently only supports managing your project dependencies (with [Nix](https://github.com/NixOS/nix)), but more should come soon (CI, development services, etc..).

## Getting started

To start using Organist, you need `Nix` to be installed and configured.
If it isn't already the case, you can get it with:

```console
$ curl -L https://nixos.org/nix/install | bash
# We also need a couple of experimental Nix features
$ mkdir -p ~/.config/nix
$ echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Then bootstrap a project with:

```console
$ nix flake init -t github:nickel-lang/organist
# Edit the project file to fit your needs
$ $EDITOR project.ncl
# Enter the environment
$ nix develop
```


## Managing your dependencies with organist

Organist can be used to declare the dependencies for your project.
These can then be instantiated using [Nix](https://nixos.org/nix).

More information on [doc/dependency-management.md](doc/dependency-management.md).

## Using without flakes

While Organist is focused on usage with flakes, you can use it without them like this:

```nix
# shell.nix
let
  pkgs = import <nixpkgs> {};
  organistSrc = builtins.fetchTarball "https://github.com/nickel-lang/organist/archive/main.tar.gz";
  organist = pkgs.callPackage "${organistSrc}/lib/lib.nix" {inherit organistSrc;};
in
  (organist.importNcl {baseDir = ./.;}).shells.default
```

And then use `nix develop -f shell.nix` as usual. Note that this will not use nixpkgs and Nickel from Organist's flake.lock.
You can use flake-compat to use them:

```nix
# shell.nix
let
  flake-compat = builtins.fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
  organistSrc = builtins.fetchTarball "https://github.com/nickel-lang/organist/archive/main.tar.gz";
  organist = ((import flake-compat) {src = organistSrc;}).defaultNix.lib.${builtins.currentSystem};
in
  (organist.importNcl {baseDir = ./.;}).shells.default
```
