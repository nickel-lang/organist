# Organist

_Control all your tooling from a single console_

Managing a project's development environment involves configuring a lot of tools and occasionally getting to communicate with each other: one (or several) package managers, a CI system, a service manager (to run that local postgresql database without which you can't test anything), custom utility scripts that end up spawning everywhere, etc.
Ni-Mh (called “nickel-nix” or “Organist” at the moment, but I really like Ni-Mh) aims at being your main entrypoint for managaing all these different tools, so that you can get:

1. A unified configuration framework for all of these
2. A powerful and ergonomic language to allow you to easily abstract over these configurations, with discoverability and early error reporting

Organist currently only supports managing your project dependencies (with [Nix](https://github.com/NixOS/nix)), but more should come soon (CI, development services, etc..).

## Getting started

To start using `nickel-nix`, you need `Nix` to be installed and configured.
If it isn't already the case, you can get it with:

```console
$ curl -L https://nixos.org/nix/install | bash
# We also need a couple of experimental Nix features
$ mkdir -p ~/.config/nix
$ echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Then bootstrap a project with:

```console
$ nix flake init -t github:nickel-lang/nickel-nix
# Edit the project file to fit your needs
$ $EDITOR project.ncl
# Enter the environment
$ nix develop
```


## Managing your dependencies with organist

Organist can be used to declare the dependencies for your project.
These can then be instantiated using [Nix](https://nixos.org/nix).

More information on <./doc/dependency-management.md>.
