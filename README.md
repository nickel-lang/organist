# Organist

_Control all your tooling from a single console_

Managing a project's development environment involves configuring a lot of tools and occasionally getting to communicate with each other: one (or several) package managers, a CI system, a service manager (to run that local postgresql database without which you can't test anything), custom utility scripts that end up spawning everywhere, etc.
Organist aims at being your main entrypoint for managaing all these different tools, so that you can get:

1. A unified configuration framework for all of these
2. A powerful and ergonomic language to allow you to easily abstract over these configurations, with discoverability and early error reporting

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

It is also possible to use Organist without flakes, see [doc/bootstrap-no-flake.md](doc/bootstrap-no-flake.md)

## Managing your dependencies with organist

Organist can be used to declare the dependencies for your project.
These can then be instantiated using [Nix](https://nixos.org/nix).

More information on [doc/dependency-management.md](doc/dependency-management.md).

## Generating files

Development projects tend to require a lot of boilerplaty files to configure
all the tools involved.
Organist can take care of these through the [`files` option](doc/filegen.md)

## Managing services

Organist also allows you to declare a set of services that need to be running when developing your project, through the [`services` option](doc/services.md)

## How does this differ from {insert your favorite tool} ?

- [Docker](https://docs.docker.com/desktop/).
    Containers can be used for providing both a coherent development environment and an arbitrary set of services (via [docker-compose](https://docs.docker.com/compose/) for instance).
    They provide a very strong isolation and are fairly easy to set up.
    They tend to be quite rigid however, both when defining the environment (maintaining complex environments in a `Dockerfile` can be challenging) and when running it.
- [Nix](https://github.com/nixos/nix), and in particular `nix-shell` and `nix develop`.
    This is one of the main building blocks of Organist.
    Nix itself acts at a lower level (it is strictly speaking a package manager), although a lot can be encoded in it.
- [Devenv](https://devenv.sh).
    This is arguably the main inspiration for Organist, with a fairly similar interface and many common principles.

    The main difference between devenv and Organist is the choice of the surface language (Nix + some YAML for devenv, Nickel for Organist).
    This has some non-trivial implications:
    The first one is that Nickel being a more modern language, with more principled (and thus easier to grasp) semantics and a great tooling out-of-the-box makes it more approachable than Nix.
    The second one is that using a different language means that we can break free from the usual Nix idioms when we know that there's a better way.

    Another important difference is that Organist tries to not sacrifice on the compatibility with Nix (by reusing the Nix command-line and exposing Flake-style outputs), meaning that Organist packages can seamlessly be integrated in Nix-based workflows.
- [Flox](https://flox.dev).
    The tool is also leveraging Nix and improving its ability to manage development environments.
    Its main focus however, is in facilitating the publishing and sharing of packages, which is orthogonal to Organist's goals.
    In fact, it would probably be possible to use Organist with Flox and get the best of both worlds.
    This is left as an exercise to the reader.
- [Devbox](https://www.jetpack.io/devbox/) is another Nix-based development environment manager.
    Like Organist, it builds beyond the “package management” aspect (to provide some service runner capability and integrate with jetpack.io amongst other things), and like Organist it replaces the Nix language by something else (JSON).
    It chooses however to expose a more constrained (and not extensible) interface in a more constrained language.
