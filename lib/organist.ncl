{
  nix
    | doc m%"
      Nix interoperability library.
    "%
    = import "./nix-interop/nix.ncl",
  modules
    | doc m%"
      implementation of a module system for Nickel, inspired by the NixOS
      module system.
    "%
    = import "./modules/main.ncl",
  shells
    | doc m%"
      Generic shells defined by Organist.

      These are meant to be used as a base for the environments, and be combined or extended:

      ### Example

      ```nickel
      {
        shells = organist.shells.Bash,
        shells = organist.shells.Rust,
        shells.build.packages.pandoc = import_nix "nixpkgs#pandoc",
      }
      ```
    "%
    = nix.shells,
  OrganistExpression
    | doc m%"
      The type of an Organist expression, defining the whole development environment.
    "%
    = (import "./schema.ncl").OrganistExpression,
  import_nix
  # XXX: That doc is duplicated from `nix-interop/builtins.ncl`.
  # Keep it in sync, and remove once https://github.com/tweag/nickel/issues/1968 is fixed.
    | doc m%%"
      Import a Nix value from one of the flake inputs.
      The value should be passed in a flakeref-like format
      `input_name#attribute_path`.

      # Example

      ```nickel
      cmd = nix-s%"%{import_nix "nixpkgs#hello"}/bin/hello > $out"%
      ```
    "%%
    = nix.builtins.import_nix,

  services
    | doc m%"
      Service management for Organist.

      Merging this module with the configuration enables the `services` option.
    "%
    = import "./services.ncl",

  tools
    | doc m%"
      Interface with various third-party tools.
    "%,
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
