let nix = import "../nix-interop/nix.ncl" in
let OrganistShells = {
  dev
    | doc m%"
      Development shell.

      Contains everything needed to build and work on the project.

      Can be entered with `nix develop .#dev`.
      "%
    | nix.derivation.NickelDerivation,
  build
    | doc m%"
      Build shell.

      Only contains the required dependencies to build the project.

      Can be entered with `nix develop .#build`.
      "%
    | nix.derivation.NickelDerivation,
  "default"
    | doc m%"
      Default shell.

      This is the shell that gets entered by `nix develop` without any argument.

      Defaults to the `dev` shell.
      "%
    | nix.derivation.NickelDerivation,
}
in
{
  Schema = {
    shells
      | doc m%"
        The shells exposed by the environment.
      "%
      | OrganistShells,
    flake.devShells | { _ | nix.derivation.Derivation },
  },
  config | Schema
    = {
      shells.dev = shells.build,
      shells."default" = shells.dev,
      flake.devShells = shells,
    },
}
