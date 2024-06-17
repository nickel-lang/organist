let nix = import "./nix-interop/nix.ncl" in

(import "./flake/shells.ncl")
& {
  Schema = {
    flake
      | doc m%"
        The raw outputs of the Nix flake.

        Don't set that directly unless you need to.
      "%,
    apps
      | doc m%"
        Applications that can be executed with `nix run .#app-name`.
      "%
      | { _ | { program | nix.derivation.NixString } },
    flake.apps | { _ | { type = "app", program | nix.derivation.NixString } },

    checks
      | doc m%"
        Checks executed when running `nix flake check`
      "%
      | { _ | nix.derivation.Derivation },
    flake.checks | { _ | nix.derivation.Derivation },

    packages
      | doc m%"
        Packages exported by the flake.
        Can be accessed with `nix build .#package-name`.
      "%
      | { _ | nix.derivation.Derivation },
    flake.packages | { _ | nix.derivation.Derivation },
  },
  config | Schema = {
      apps = {},
      flake.apps = nix.derivation.trim_derivation_args apps,
      checks = {},
      flake.checks = nix.derivation.trim_derivation_args checks,
      packages = {},
      flake.packages = nix.derivation.trim_derivation_args packages,
    },
}
