{
  nix = import "./nix-interop/nix.ncl",
  shells = nix.shells,
  schema = import "./schema.ncl",
  OrganistExpression = schema.OrganistExpression,
  import_nix = nix.builtins.import_nix,

  services = import "./services.ncl",

  tools.editorconfig = import "./editorconfig.ncl",
  tools.direnv = import "./direnv.ncl",
}
#TODO: currently, Nickel forbids doc at the toplevel. It's most definitely
# temporary, as the implementation of RFC005 is ongoing. Once the capability is
# restored, remove this message and uncomment the following lines.
#
# | doc m%"
#     Nickel library for organist interoperability. Provide contracts used to
#     serialize Nix inputs to Nickel, to define a Nickel expression, and helpers
#     to build strings which preserves Nix string contexts.
#   "%
