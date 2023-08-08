let inputs = import "./nickel.lock.ncl" in
let nickel-nix = inputs.nickel-nix in

{
  shells = inputs.nickel-nix.shells.Bash,
} | inputs.nickel-nix.contracts.NixelExpression
