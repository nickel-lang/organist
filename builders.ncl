let { NickelDerivation, .. } = import "contracts.ncl" in

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

  BashShell = {
    inputs_spec = {
      bash = {},
      # Setting the following as a default value conflicts with InputsSpec's
      # contract default value (`"nixpkgs"`). Maybe InputsSpec shouldn't set a
      # default value at all?
      # That being said, `naked_std_env` is an internal compatibility value:
      # there doesn't seem to be a good reason to make it a default value. It
      # can still be overridden using `force` if really needed
      naked_std_env.input = "nickel-nix-internals",
    },
    inputs,

    output =
      {
        version | default = "0.1",

        # This is required otherwise nix develop will fail with a message that it
        # only supports bash.
        build_command = {
          cmd = nix-s%"%{inputs.bash}/bin/bash"%,
          args = [],
        },

        structured_env = {
          # TODO: handle naked derivations without having to interpolate
          stdenv.naked_std_env = nix-s%"%{inputs.naked_std_env}"%,
        },

        packages = { bash = inputs.bash },

        structured_env.PATH =
          packages
          |> std.record.map
            (
              fun _n p =>
                nix-s%"%{p}/bin"%
            ),

        # Compute `env` from `structured_env`. Note that thanks to recursive
        # overriding, if stuff is added to `structured_env` through merging,
        # `env` will be automatically up-to-date
        env =
          structured_env
          |> std.record.map
            (
              fun _n xs =>
                # Intersperse ':' between environment variable fragments
                let values = std.record.values xs in
                let first = std.array.first values in
                values
                |> std.array.drop_first
                |> std.array.fold_left (fun acc value => nix-s%"%{acc}:%{value}"%) first
            ),
      } | NickelPkg,
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
        intelephense = {
          path = "nodePackages"."intelephense",
        },
      },
      inputs,

      output.packages = {
        php = inputs.php,
        intelephense = inputs.intelephense,
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

  # nodePackages_latest.typescript-language-server is marked broken in nixpkgs
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

  # broken: PyLTI-0.7.0 not supported for interpreter python3.10
  # works with a regular nix shell though
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
      ghcVersion, # User-defined. To keep in sync with the one used by stack
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
            export PATH="%{inputs.coreutils}/bin:$PATH"
            mkdir -p $out/bin
            echo "$0" > $out/bin/stack
            chmod a+x $out/bin/*
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
