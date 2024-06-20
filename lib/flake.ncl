let nix = import "./nix-interop/nix.ncl" in

(import "./flake/shells.ncl")
& {
  Schema = {
    flake
      | { .. }
      | doc m%"
        The raw value sent to Nix as the final content of the Flake.

        Don't set this directly unless you really need to.
      "%,

    apps
      | doc m%"
        Applications that can be executed with `nix run .#app-name`.
      "%
      | { _ | { program | nix.nix_string.NixString } },
    flake.apps | { _ | { type = "app", program | nix.nix_string.NixString } },

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
  config | Schema
    = {
      apps = {},
      flake.apps = apps,
      checks = {},
      flake.checks = checks,
      packages = {},
      flake.packages = packages,
    },
}
