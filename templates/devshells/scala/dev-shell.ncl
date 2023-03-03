let builders = import "nixel/builders.ncl" in

{
  output = {
    name = "nickel-shell",
  }
} & builders.ScalaShell
