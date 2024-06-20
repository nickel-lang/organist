let filegen = import "files.ncl" in
let lockfile = import "lockfile.ncl" in
let flake = import "flake.ncl" in
let services = import "services.ncl" in
let direnv = import "direnv.ncl" in
{
  # TODO: have the actual contract for the result of an expression. It's pretty
  # open (could be an integer, a derivation, a record of derivations, etc.) but
  # it still obeys some rules: if the `type` field is set to a known predefined
  # value, then the record must have a certain shape.
  #
  # The contract must be: what the Nix side of the code can "parse" without
  # erroring out.
  OrganistExpression =
    { Schema, config | Schema }
    & flake
    & filegen
    & lockfile
    & services
    & direnv
    & (import "just.ncl")
}
