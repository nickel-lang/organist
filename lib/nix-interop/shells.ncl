let builders = import "builders.ncl" in
let nix_builtins = import "builtins.ncl" in

let concat_strings_sep = fun sep values =>
  if std.array.length values == 0 then
    ""
  else
    std.array.reduce_left (fun acc value => nix-s%"%{acc}%{sep}%{value}"%) values
in

{
  Bash = {
    build =
      builders.Shell
      & {
        packages = {
          bash = nix_builtins.import_nix "nixpkgs#bash",
        },
      },
    dev.packages.nickel = nix_builtins.import_nix "organist#nickel",
  },

  Rust =
    Bash
    & {
      build.packages = {
        cargo = nix_builtins.import_nix "nixpkgs#cargo",
        rustc = nix_builtins.import_nix "nixpkgs#rustc",
      },
      dev.packages = {
        rustfmt = nix_builtins.import_nix "nixpkgs#rustfmt",
        rust-analyzer = nix_builtins.import_nix "nixpkgs#rust-analyzer",
      },
    },

  Go =
    Bash
    & {
      build.packages.go = nix_builtins.import_nix "nixpkgs#go",
      dev.packages.gopls = nix_builtins.import_nix "nixpkgs#gopls",
    },

  Clojure =
    Bash
    & {
      build.packages.clojure = nix_builtins.import_nix "nixpkgs#clojure",
      dev.packages.clojure-lsp = nix_builtins.import_nix "nixpkgs#clojure-lsp",
    },

  C =
    Bash
    & {
      build.packages.clang = nix_builtins.import_nix "nixpkgs#clang",
      dev.packages.clang-tools = nix_builtins.import_nix "nixpkgs#clang-tools",
    },

  # intelephense is currently broken in nixpkgs
  Php =
    Bash
    & {
      build.packages.php = nix_builtins.import_nix "nixpkgs#php",
      # Not included because unfree
      # dev.packages.intelephense = nix_builtins.import_nix "nixpkgs#nodePackages.intelephense",
    },

  Zig =
    Bash
    & {
      build.packages.zig = nix_builtins.import_nix "nixpkgs#zig",
      dev.packages.zls = nix_builtins.import_nix "nixpkgs#zls",
    },

  Javascript =
    Bash
    & {
      build.packages.nodejs = nix_builtins.import_nix "nixpkgs#nodejs",
      dev.packages.ts-lsp = nix_builtins.import_nix "nixpkgs#nodePackages_latest.typescript-language-server",
    },

  Racket =
    Bash
    & {
      build.packages = {
        racket = nix_builtins.import_nix "nixpkgs#racket",
      },
    },

  Scala =
    Bash
    & {
      build.packages.scala = nix_builtins.import_nix "nixpkgs#scala",
      dev.packages.metals = nix_builtins.import_nix "nixpkgs#metals",
    },

  Python310 =
    Bash
    & {
      build.packages.python = nix_builtins.import_nix "nixpkgs#python310",
      dev.packages.python-lsp = nix_builtins.import_nix "nixpkgs#python310Packages.python-lsp-server",
    },

  Erlang =
    Bash
    & {
      build.packages.erlang = nix_builtins.import_nix "nixpkgs#erlang",
      dev.packages.erlang-lsp = nix_builtins.import_nix "nixpkgs#erlang-ls",
    },

  HaskellStack =
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
    },
}
