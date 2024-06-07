let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression
& organist.tools.editorconfig
& {
  Schema,
  config | Schema = {
      shells = organist.shells.Bash,

      shells.build = {
        packages = {},
      },

      shells.dev = {
        packages.hello = organist.import_nix "nixpkgs#hello",
      },

      editorconfig.sections = {
        "*".indent_style = 'space,
        "*".indent_size = 2,
        "*".insert_final_newline = true,
        "Makefile".indent_style = 'tab,
        "*.py" = {
          indent_style = 'space,
          indent_size = 4,
        },
      },
    },
}
  | organist.modules.T
