let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in
let import_nix = organist.lib.import_nix in

{
  shells =
    organist.shells.Bash
    & {
      build.packages = {
        nickel = import_nix "nixpkgs#nickel",
        parallel = import_nix "nixpkgs#parallel",
        gnused = import_nix "nixpkgs#gnused",
      },
      dev.packages = {
        nls = import_nix "nixpkgs#nls",
      },
    },

  flake.apps.run-test =
    let testScript | organist.builders.ShellApplication = {
        name = "run-test.sh",
        file = "./run-test.sh",
        runtime_inputs = {
          nickel = organist.lib.import_nix "nixpkgs#nickel",
          parallel = import_nix "nixpkgs#parallel",
          gnused = import_nix "nixpkgs#gnused",
        },
      }
      in
    {
      type = "app",
      program | organist.contracts.NixString = nix-s%"%{testScript}/bin/run-test.sh"%
    },

  flake.checks = import "tests/main.ncl",
}
  | organist.contracts.OrganistExpression
