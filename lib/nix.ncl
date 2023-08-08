{
  lib = import "lib.ncl",
  builders = import "builders.ncl",
  contracts = import "contracts.ncl",
}
#TODO: currently, Nickel forbids doc at the toplevel. It's most definitely
# temporary, as the implementation of RFC005 is ongoing. Once the capability is
# restored, remove this message and uncomment the following lines.
#
# | doc m%"
#     Nickel library for Nickel-Nix interoperability. Provide contracts used to
#     serialize Nix inputs to Nickel, to define a Nickel expression, and helpers
#     to build strings which preserves Nix string contexts.
#   "%
