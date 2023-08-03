let inputs = import "./nickel.lock.ncl" in
let nickel-nix = inputs.nickel-nix in

{
  shells = nickel-nix.shells.Bash
}
