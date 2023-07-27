let { NickelDerivation, Derivation, NixString, .. } = import "contracts.ncl" in

let lib = import "lib.ncl" in

let concat_strings_sep = fun sep values =>
  if std.array.length values == 0 then "" else
    std.array.reduce_left (fun acc value => nix-s%"%{acc}%{sep}%{value}"%) values
in
{
  NickelPkg
  # we should only need two '%%', but a current Nickel bug (#XXX) bug makes the example being
  # recognized as actual interpolation. For the time being, we thus use a
  # three '%' delimiter.
    | doc m%%%"
      The most basic builder. Simply alias to `NickelDerivation`.

      Example:

      Here is a simple example of a function producing a Nickel derivation
      using the `NickelPkg` builder.

      ```nickel
      output = fun { inputs, nix, .. } =>
      {
        name = "hello",
        version = "0.1",
        build_command = {
          cmd = nix-s%"%{inputs.bash}/bin/bash"%,
          args = [ "-c",
            nix-s%"
              %{inputs.gcc}/bin/gcc %{nix.lib.import_file "hello.c"} -o hello
              %{inputs.coreutils}/bin/mkdir -p $out/bin
              %{inputs.coreutils}/bin/cp hello $out/bin/hello
             "%
          ]
        },
        env = {},
      } | nix.builders.NickelPkg
      ```
      "%%%
    = NickelDerivation,

  NixpkgsPkg
    | doc m%"
      Makes a derivation that runs all the build phases from nixpkgs' stdenv as the `build_command`.
      Can be controlled with environment variables in the same way as `stdenv.mkDerivation`.
    "%
    = {
      output = {
        name,
        version,
        build_command = {
          cmd = nix-s%"%{lib.import_nix "nixpkgs#bash"}/bin/bash"%,
          args = ["-c", "set -euo pipefail; source .attrs.sh; source $stdenv/setup; genericBuild"],
        },
        structured_env = {},
        env = {
          stdenv = lib.import_nix "nixpkgs#stdenv"
        },
        attrs = env & structured_env,
      } | NickelPkg,
    },

  Shell
    | doc m%"
      A derivation that is to be used as a shell, e.g. with `nix develop`.
      Analogous to `mkShell`.
    "%
    = NixpkgsPkg & {
      hooks | doc "Bash scripts to run when entering the shell" = {},

      output = {
        name | default = "shell",
        version | default = "dev",
        packages | doc "Packages to be added to the shell, setting PATH, LD_LIBRARY_PATH and other variables as needed" = {},

        env.buildCommand = nix-s%"
          echo "This derivation is not supposed to be built" 1>&2 1>/dev/null
          exit 1
        "%,
        env.shellHook = concat_strings_sep "\n" (std.record.values hooks),
        structured_env.buildInputs = packages,
      } | (NickelPkg & { packages | { _ : Derivation } }),
    },

  BashShell = Shell & {
    output.packages = {
      bash = lib.import_nix "nixpkgs#bash",
    },
  },

  RustShell =
    BashShell
    & {
      output.packages = {
        cargo = lib.import_nix "nixpkgs#cargo",
        rustc = lib.import_nix "nixpkgs#rustc",
        rustfmt = lib.import_nix "nixpkgs#rustfmt",
        rust-analyzer = lib.import_nix "nixpkgs#rust-analyzer",
      },
    },

  GoShell =
    BashShell
    & {
      output.packages = {
        go = lib.import_nix "nixpkgs#go",
        gopls = lib.import_nix "nixpkgs#gopls",
      },
    },

  ClojureShell =
    BashShell
    & {
      output.packages = {
        clojure = lib.import_nix "nixpkgs#clojure",
        clojure-lsp = lib.import_nix "nixpkgs#clojure-lsp",
      },
    },

  CShell =
    BashShell
    & {
      output.packages = {
        clang = lib.import_nix "nixpkgs#clang",
        clang-tools = lib.import_nix "nixpkgs#clang-tools",
      },
    },

  # intelephense is currently broken in nixpkgs
  PhpShell =
    BashShell
    & {
      output.packages = {
        php = lib.import_nix "nixpkgs#php",
        # Not included because unfree
        # intelephense = lib.import_nix "nixpkgs#nodePackages.intelephense",
      },
    },

  ZigShell =
    BashShell
    & {
      output.packages = {
        zig = lib.import_nix "nixpkgs#zig",
        zls = lib.import_nix "nixpkgs#zls",
      },
    },

  JavascriptShell =
    BashShell
    & {
      output.packages = {
        nodejs = lib.import_nix "nixpkgs#nodejs",
        ts-lsp = lib.import_nix "nixpkgs#nodePackages_latest.typescript-language-server",
      },
    },

  RacketShell =
    BashShell
    & {
      output.packages = {
        racket = lib.import_nix "nixpkgs#racket",
      },
    },

  ScalaShell =
    BashShell
    & {
      output.packages = {
        scala = lib.import_nix "nixpkgs#scala",
        metals = lib.import_nix "nixpkgs#metals",
      },
    },

  Python310Shell =
    BashShell
    & {
      output.packages = {
        python = lib.import_nix "nixpkgs#python310",
        python-lsp = lib.import_nix "nixpkgs#python310Packages.python-lsp-server",
      },
    },

  ErlangShell =
    BashShell
    & {
      output.packages = {
        erlang = lib.import_nix "nixpkgs#erlang",
        erlang-lsp = lib.import_nix "nixpkgs#erlang-ls",
      },
    },

  HaskellStackShell =
    BashShell
    & {
      ghcVersion | default = "927", # User-defined. To keep in sync with the one used by stack
      output.packages =
        let stack-wrapped =
          {
            name = "stack-wrapped",
            version = "1.0",
            build_command = {
              cmd = nix-s%"%{lib.import_nix "nixpkgs#bash"}/bin/bash"%,
              args = [
                "-c",
                # Sorry about Topiary formatting of the following lines
                nix-s%"
            source .attrs.sh
            export PATH='%{lib.import_nix "nixpkgs#coreutils"}/bin'":$PATH"
            mkdir -p ${outputs[out]}/bin
            echo "$0" > ${outputs[out]}/bin/stack
            chmod a+x ${outputs[out]}/bin/*
          "%,
                nix-s%"
            #!%{lib.import_nix "nixpkgs#bash"}/bin/bash
            %{lib.import_nix "nixpkgs#stack"}/bin/stack \
              --nix \
              --no-nix-pure \
              --nix-path="nixpkgs=%{lib.import_nix "nixpkgs#path"}" \
              "$@"
          "%,
              ],
            },
          } | NickelPkg
        in
        {
          stack = stack-wrapped,
          stack' = lib.import_nix "nixpkgs#stack",
          ormolu = lib.import_nix "nixpkgs#ormolu",
          nix = lib.import_nix "nixpkgs#nix",
          git = lib.import_nix "nixpkgs#git",
          haskell-language-server = lib.import_nix "nixpkgs#haskell.packages.ghc%{ghcVersion}.haskell-language-server",
        },
    },
}
