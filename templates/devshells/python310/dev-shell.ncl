let builders = import "builders.ncl" in

{
  output = {
    name = "nickel-shell",
  }
} & builders.Python310Shell
