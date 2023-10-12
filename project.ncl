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

  flake.apps.run-test =
    let testScript | organist.builders.ShellApplication = {
        name = "run-test.sh",
        content.file = organist.lib.import_file "run-test.sh",
        runtime_inputs = {
          nickel = organist.lib.import_nix "nickel#nickel-lang-cli",
          parallel = import_nix "nixpkgs#parallel",
          gnused = import_nix "nixpkgs#gnused",
        },
      }
      in
    {
      type = "app",
      program | organist.contracts.NixString = nix-s%"%{testScript}/bin/run-test.sh"%
    },

  flake.checks
    | {
      _ | {
        version
        = "",
        env.stdenv
        = import_nix "nixpkgs#stdenvNoCC",
        ..
      }
    }
    | { _ | organist.builders.NixpkgsPkg }
    = {
      alejandra = {
        name = "check-alejandra",
        env.buildCommand = nix-s%"
          %{import_nix "nixpkgs#alejandra"}/bin/alejandra --check %{import_nix "self"}
          touch $out
        "%,
      },

      nickel-format = {
        name = "check-nickel-format",
        env.buildInputs.nickel = import_nix "nickel#nickel-lang-cli",
        env.buildCommand = nix-s%"
          cd %{import_nix "self"}
          failed=""
          for f in $(find . -name future -prune -or -name '*.ncl' -print); do
            if ! diff -u "$f" <(nickel format -f "$f"); then
              failed="$failed $f"
            fi
          done
          if [ "$failed" != "" ]; then
            echo "Following files need to be formatted: $failed"
            exit 1
          fi
          touch $out
        "%,
      },
    },

  flake.checks = import "tests/main.ncl",
}
  | organist.contracts.OrganistExpression
