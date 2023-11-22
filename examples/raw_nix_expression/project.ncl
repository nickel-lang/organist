let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  shells = organist.shells.Bash,

  shells.build = {
    packages = {},
  },

  shells.dev = {
    packages.python =
      organist.nix.derivation.CallNix
      & {
        function = m%"
          { python }: python.withPackages (p: [p.pyyaml])
        "%,
        args = {
          python = organist.import_nix "nixpkgs#python3"
        },
      },
  },
} | organist.OrganistExpression
