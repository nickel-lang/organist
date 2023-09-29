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
}
  | organist.contracts.OrganistExpression
