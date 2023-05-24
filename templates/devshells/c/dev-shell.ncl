let builders = (import "./nickel.lock.ncl").nickel-nix.builders in

{
  output = {
    name = "nickel-shell",
  }
}
& builders.CShell
