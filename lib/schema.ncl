let nix = import "./nix-interop/nix.ncl" in
let filegen = import "files.ncl" in
{
  OrganistShells = {
    dev
      | doc m%"
          Development shell.

          Contains everything needed to build and work on the project.

          Can be entered with `nix develop .#dev`.
        "%
      | nix.derivation.NickelDerivation
      = build,
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
      | nix.derivation.NickelDerivation
      = dev,
  },

  FlakeOutputs = {
    packages | { _ | nix.derivation.Derivation } | optional,
    checks | { _ | nix.derivation.Derivation } | optional,
    devShells | { _ | nix.derivation.Derivation } | optional,
    apps | { _ | { type = "app", program | nix.derivation.NixString } } | optional,
  },

  # TODO: have the actual contract for the result of an expression. It's pretty
  # open (could be an integer, a derivation, a record of derivations, etc.) but
  # it still obeys some rules: if the `type` field is set to a known predefined
  # value, then the record must have a certain shape.
  #
  # The contract must be: what the Nix side of the code can "parse" without
  # erroring out.
  OrganistExpression =
    {
      Schema = {
        shells
          | doc m%"
            The shells that will be entered by `nix develop`.
          "%
          | OrganistShells,
        flake
          | doc m%"
            The raw flake outputs that will be passed to Nix.

            These should follow the Nix flake outputs schema.
          "%
          | FlakeOutputs
          = {},
      },
      config | Schema = {
          shells,
          flake.devShells = shells,
        },
    }
    & filegen
}
