let builders = (import "./nickel.lock.ncl").nickel-nix.builders in

{
  ghcVersion = "927",
  output = {
    name = "nickel-shell",
  }
}
& builders.HaskellStackShell
