let { NickelDerivation, Derivation, NixString, .. } = import "contracts.ncl" in

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
      inputs_spec = {
        bash.input | default = "nixpkgs",
        stdenv.input | default = "nixpkgs",
      },
      inputs,
      output = {
        name,
        version,
        build_command = {
          cmd = nix-s%"%{inputs.bash}/bin/bash"%,
          args = ["-c", "set -euo pipefail; source .attrs.sh; source $stdenv/setup; genericBuild"],
        },
        structured_env = {},
        env = {
          stdenv = inputs.stdenv,
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
    inputs_spec = {
      bash.input | default = "nixpkgs",
    },
    inputs,
    output.packages = {
      bash = inputs.bash,
    },
  },

  RustShell =
    BashShell
    & {
      inputs_spec = {
        cargo = {},
        rustc = {},
        rustfmt = {},
        rust-analyzer = {},
      },
      inputs,

      output.packages = {
        cargo = inputs.cargo,
        rustc = inputs.rustc,
        rustfmt = inputs.rustfmt,
        rust-analyzer = inputs.rust-analyzer,
      },
    },

  GoShell =
    BashShell
    & {
      inputs_spec = {
        go = {},
        gopls = {},
      },
      inputs,

      output.packages = {
        go = inputs.go,
        gopls = inputs.gopls,
      },
    },

  ClojureShell =
    BashShell
    & {
      inputs_spec = {
        clojure = {},
        clojure-lsp = {},
      },
      inputs,

      output.packages = {
        clojure = inputs.clojure,
        clojure-lsp = inputs.clojure-lsp,
      },
    },

  CShell =
    BashShell
    & {
      inputs_spec = {
        clang = {},
        clang-tools = {},
      },
      inputs,

      output.packages = {
        clang = inputs.clang,
        clang-tools = inputs.clang-tools,
      },
    },

  # intelephense is currently broken in nixpkgs
  PhpShell =
    BashShell
    & {
      inputs_spec = {
        php = {},
      },
      inputs,

      output.packages = {
        php = inputs.php,
      },
    },

  ZigShell =
    BashShell
    & {
      inputs_spec = {
        zig = {},
        zls = {},
      },
      inputs,

      output.packages = {
        zig = inputs.zig,
        zls = inputs.zls,
      },
    },

  JavascriptShell =
    BashShell
    & {
      inputs_spec = {
        nodejs = {},
        typescript-language-server = {
          path = "nodePackages_latest.typescript-language-server",
        }
      },
      inputs,

      output.packages = {
        nodejs = inputs.nodejs,
        ts-lsp = inputs.typescript-language-server,
      },
    },

  RacketShell =
    BashShell
    & {
      inputs_spec = {
        racket = {},
      },
      inputs,

      output.packages = {
        racket = inputs.racket,
      },
    },

  ScalaShell =
    BashShell
    & {
      inputs_spec = {
        scala = {},
        metals = {},
      },
      inputs,

      output.packages = {
        scala = inputs.scala,
        metals = inputs.metals,
      },
    },

  Python310Shell =
    BashShell
    & {
      inputs_spec = {
        python310 = {},
        python-lsp-server = {
          path = "python310Packages.python-lsp-server",
        }
      },
      inputs,

      output.packages = {
        python = inputs.python310,
        python-lsp = inputs.python-lsp-server,
      },
    },

  ErlangShell =
    BashShell
    & {
      inputs_spec = {
        erlang = {},
        erlang-ls = {},
      },
      inputs,

      output.packages = {
        erlang = inputs.erlang,
        erlang-lsp = inputs.erlang-ls,
      },
    },

  HaskellStackShell =
    BashShell
    & {
      ghcVersion | default = "927", # User-defined. To keep in sync with the one used by stack
      inputs_spec = {
        stack = {},
        ormolu = {},
        nix = {},
        git = {},
        coreutils = {},
        haskell-language-server = {
          path = "haskell.packages.ghc%{ghcVersion}.haskell-language-server",
        },
        # This will point to a copy of nixpkgs in nix store
        path = {},
      },
      inputs,

      output.packages =
        let stack-wrapped =
          {
            name = "stack-wrapped",
            version = inputs.stack.version,
            build_command = {
              cmd = nix-s%"%{inputs.bash}/bin/bash"%,
              args = [
                "-c",
                # Sorry about Topiary formatting of the following lines
                nix-s%"
            source .attrs.sh
            export PATH='%{inputs.coreutils}/bin'":$PATH"
            mkdir -p ${outputs[out]}/bin
            echo "$0" > ${outputs[out]}/bin/stack
            chmod a+x ${outputs[out]}/bin/*
          "%,
                nix-s%"
            #!%{inputs.bash}/bin/bash
            %{inputs.stack}/bin/stack \
              --nix \
              --no-nix-pure \
              --nix-path="nixpkgs=%{inputs.path}" \
              "$@"
          "%,
              ],
            },
          } | NickelPkg
        in
        {
          stack = stack-wrapped,
          stack' = inputs.stack,
          ormolu = inputs.ormolu,
          nix = inputs.nix,
          git = inputs.git,
          haskell-language-server = inputs.haskell-language-server,
        },
    },
}
