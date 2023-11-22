let builders = import "../builders.ncl" in
let nix_builtins = import "../builtins.ncl" in
let Bash = import "./bash.ncl" in
Bash
& {
  build.ghcVersion
    | doc m%"
            The GHC version used in the build.
            Must be kept in sync with the one expected by Stack.
          "%
    | String
    | default
    = "927",
  build.packages =
    let stack-wrapped =
      {
        name = "stack-wrapped",
        version = "1.0",
        build_command = {
          cmd = nix-s%"%{nix_builtins.import_nix "nixpkgs#bash"}/bin/bash"%,
          args = [
            "-c",
            nix-s%"
                  source .attrs.sh
                  export PATH='%{nix_builtins.import_nix "nixpkgs#coreutils"}/bin'":$PATH"
                  mkdir -p ${outputs[out]}/bin
                  echo "$0" > ${outputs[out]}/bin/stack
                  chmod a+x ${outputs[out]}/bin/*
                "%,
            nix-s%"
                  #!%{nix_builtins.import_nix "nixpkgs#bash"}/bin/bash
                  %{nix_builtins.import_nix "nixpkgs#stack"}/bin/stack \
                    --nix \
                    --no-nix-pure \
                    --nix-path="nixpkgs=%{nix_builtins.import_nix "nixpkgs#path"}" \
                    "$@"
                "%,
          ],
        },
      }
        | builders.NickelPkg
    in
    {
      stack = stack-wrapped,
      stack' = nix_builtins.import_nix "nixpkgs#stack",
      nix = nix_builtins.import_nix "nixpkgs#nix",
      git = nix_builtins.import_nix "nixpkgs#git",
    },
  dev.ghcVersion | force = build.ghcVersion,
  dev.packages = {
    ormolu = nix_builtins.import_nix "nixpkgs#ormolu",
    haskell-language-server = nix_builtins.import_nix "nixpkgs#haskell.packages.ghc%{dev.ghcVersion}.haskell-language-server",
  },
}
