let inputs = import "./nickel.lock.ncl" in
let nickel-nix = inputs.nickel-nix in

{
  output = {
    name = "nickel-shell",
  }
}
& nickel-nix.builders.BashShell
