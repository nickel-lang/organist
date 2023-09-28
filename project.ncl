let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in
let import_nix = organist.lib.import_nix in

{
  shells =
    organist.shells.Bash
    & {
      build.packages = {
        nickel-lang-cli = import_nix "nickel#nickel-lang-cli",
        parallel = import_nix "nixpkgs#parallel",
        gnused = import_nix "nixpkgs#gnused",
      },
      dev.packages = {
        nls = import_nix "nickel#lsp-nls",
      },
    },
}
  | organist.contracts.OrganistExpression
