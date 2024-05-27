let builders = import "builders.ncl" in
let nix_builtins = import "builtins.ncl" in
let packages = import "packages.ncl" in

let concat_strings_sep = fun sep values =>
  if std.array.length values == 0 then
    ""
  else
    std.array.reduce_left (fun acc value => nix-s%"%{acc}%{sep}%{value}"%) values
in

{
  Bash = import "./shells/bash.ncl",
  Rust = import "./shells/rust.ncl",

  Go =
    Bash
    & {
      build.packages = { go },
      dev.packages = { gopls },
    },

  Clojure =
    Bash
    & {
      build.packages = { clojure },
      dev.packages = { clojure-lsp },
    },

  C =
    Bash
    & {
      build.packages = { clang },
      dev.packages = { clang-tools },
    },

  # intelephense is currently broken in nixpkgs
  Php =
    Bash
    & {
      build.packages = { php },
      # Not included because unfree
      # dev.packages.intelephense = packages.import_nix "nixpkgs#nodePackages.intelephense",
    },

  Zig =
    Bash
    & {
      build.packages = { zig },
      dev.packages = { zls },
    },

  Javascript =
    Bash
    & {
      build.packages = { nodejs },
      dev.packages.ts-lsp = packages.import_nix "nixpkgs#nodePackages_latest.typescript-language-server",
    },

  Racket =
    Bash
    & {
      build.packages = {
        racket,
      },
    },

  Scala =
    Bash
    & {
      build.packages = { scala },
      dev.packages = { metals },
    },

  Python311 =
    Bash
    & {
      build.packages.python = packages.import_nix "nixpkgs#python311",
      dev.packages.python-lsp = packages.import_nix "nixpkgs#python311Packages.python-lsp-server",
    },

  Erlang =
    Bash
    & {
      build.packages = { erlang },
      dev.packages.erlang-lsp = packages.import_nix "nixpkgs#erlang-ls",
    },

  HaskellStack = import "./shells/haskell.ncl",

  OCaml =
    Bash
    & {
      build.packages = { ocaml },
      build.packages.dune = packages.import_nix "nixpkgs#dune_3",
      build.packages = { opam },
      dev.packages.ocaml-lsp = packages.import_nix "nixpkgs#ocamlPackages.ocaml-lsp",

      dev.hooks.enter_opam_env = m%"
        echo "==> Reloading the OPAM environment."
        echo "==> Set 'shells.dev.hooks.enter_opam_env' to false to disable."
        eval $(opam env)
      "%,
    },
}
