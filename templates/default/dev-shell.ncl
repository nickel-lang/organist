let nixel = (import "./nickel.lock.ncl").nickel-nix in

{
  output = {
    name = "nickel-shell",
  }
}
& nixel.builders.BashShell
