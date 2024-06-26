let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression
& organist.tools.direnv
& {
  Schema,
  config | Schema
    = {
      shells = organist.shells.Bash,

      shells.build = {
        packages = {},
      },

      shells.dev = {
        packages.direnv = organist.import_nix "nixpkgs#direnv"
      },
    },
} | organist.modules.T
