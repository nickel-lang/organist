let builders = import "builders.ncl" in

{
  output = {
    name = "nickel-shell",
  }
} & builders.BashShell
