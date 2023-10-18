let nix = import "./nix-interop/nix.ncl" in
let filegen = import "files.ncl" in
{
  OrganistShells = {
    dev | nix.derivation.NickelDerivation = build,
    build | nix.derivation.NickelDerivation,
    "default" | nix.derivation.NickelDerivation = dev,
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
      shells
        | OrganistShells
        | optional,
      flake | FlakeOutputs = {},
      ..
    }
    & filegen.Schema
}
