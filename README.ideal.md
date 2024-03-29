_Ni-Mh — batteries included environments with Nickel inside_.

Managing a project's development environment involves configuring a lot of tools and occasionally getting to communicate with each other: one (or several) package managers, a CI system, a service manager (to run that local postgresql database without which you can't test anything), custom utility scripts that end up spawning everywhere, etc.
Ni-Mh (called “nickel-nix” or “Nixel” at the moment, but I really like Ni-Mh) aims at being your main entrypoint for managaing all these different tools, so that you can get:

1. A unified configuration framework for all of these
2. A powerful and ergonomic language to allow you to easily abstract over these configurations, with discoverability and early error reporting

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

## Managing your environment with Nixel

### Dependencies

Nixel can be used to declare the dependencies for your project.
These can then be instantiated using [Nix](https://nixos.org/nix).

More information on <./doc-ideal/dependency-management.md>.

### CI configuration

You can use Nixel to generate a CI configuration.
This is extremely handy if you want to test some non-trivial matrix of platforms/configuration.

> TODO: Document

### Development services

Nixel can also be used for some simple service management.
In combination with the Nix integration, this allows you to quickly spawn any service that you might depend on.

Once the services have been defined in your `project.ncl` file, you can run `nixel up` to start them.

> TODO: Document

### Deployment

If you want to push things yet a bit further, Nixel can also be used to manage the deployment of your project, using for instance [tf-ncl](https://github.com/tweag/tf-ncl) or [nickel-kubernetes](https://github.com/tweag/nickel-kubernetes/).

> TODO: Document

## Structure of the `project.ncl` file

`project.ncl` is the main entrypoint for `nickel-nix`.
It describes the packages that should be included in your development environment, as well as the template for any file you'd like to generate:

```nickel
let Nixel = import ".nickel-nix/lock.ncl" in
let inputs = Nixel.nix.import_flake "." in
{
  shells = Nixel.shells.Rust,
  shells = Nixel.shells.Nickel,

  shells.build = {
    packages = [inputs.nixpkgs.pandoc],
    scripts = {
      build = nix-s%"
                #!/usr/bin/env bash

                %{inputs.nixpkgs.gnumake}/bin/make -j$(nproc) -l$(nproc)
            "%,
    },
  },

  shells.dev = {
    env = {
      DEV_ENDPOINT = "http://localhost:1234",
    },
    packages = [inputs.nixpkgs.nodePackages.prettier],
  },
  services = {
    postgresql = Nixel.services.postgresql,
    redis.start = nix-s%"
            %{inputs.nixpkgs.redis}/bin/redis
        "%,
    # Optional, will do the right things by default
    # redis.stop = "kill $PID",
  },
  ci.github_actions =
    let CI = Nixel.CI.GithubActions in
      {
        jobs.build =
          CI.matrix
            {
              system = [{ os : "ubuntu-latest" }, { os : "macos-latest" }],
              configVariant = ["FOO=1", "FOO=2"],
              config = [
                {
                  system | { os : String },
                  steps =
                    # The steps that you'll want in nearly any case: Checkout the repo,
                    # check that the Nixel configuration is up-to-date, etc..
                    CI.standardSteps
                    + [
                      (
                        CI.steps.runInEnv
                          m%"
                %{configVariant} build
                make check
                "%
                      )
                      & { name = "test" }
                    ],
                }
              ],
            }.config,
      },
}
```

## Local overrides

If a file `project.local.ncl` is present, then it will be merged with `project.ncl`. This allows locally overriding some parts of the development environment.

For instance, a `project.local.ncl` like the below will add [hyperfine](https://github.com/sharkdp/hyperfine) to the development shell:

```nickel
let Nixel = import ".nickel-nix/lock.ncl" in
{
  shells.dev.packages = [ Nixel.nix.inputs.nixpkgs.hyperfine ],
}
```
