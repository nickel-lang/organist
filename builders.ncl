let {NickelDerivation, ..} = import "contracts.ncl" in

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
      bash.input | default = "nixpkgs",
      # Setting the following as a default value conflicts with InputsSpec's
      # contract default value (`"nixpkgs"`). Maybe InputsSpec shouldn't set a
      # default value at all?
      # That being said, `naked_std_env` is an internal compatibility value:
      # there doesn't seem to be a good reason to make it a default value. It
      # can still be overridden using `force` if really needed
      naked_std_env.input = "nickel-nix-internals",
    },
    inputs,

    output = {
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
        PATH.bash = nix-s%"%{inputs.bash}/bin"%,
      },

      # Compute `env` from `structured_env`. Note that thanks to recursive
      # overriding, if stuff is added to `structured_env` through merging,
      # `env` will be automatically up-to-date
      env =
        structured_env
        |> std.record.map (fun _n xs =>
          # Intersperse ':' between environment variable fragments
          let values = std.record.values xs in
          let first = std.array.first values in
          values
          |> std.array.drop_first
          |> std.array.fold_left (fun acc value => nix-s%"%{acc}:%{value}"%) first
        ),
    } | NickelPkg,
  },

  RustShell = BashShell & {
    inputs_spec = {
      cargo.input | default = "nixpkgs",
      rustc.input | default = "nixpkgs",
      rustfmt.input | default = "nixpkgs",
      rust-analyzer.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        cargo = nix-s%"%{inputs.cargo}/bin"%,
        rustc = nix-s%"%{inputs.rustc}/bin"%,
        rustfmt = nix-s%"%{inputs.rustfmt}/bin"%,
        rust-analyzer = nix-s%"%{inputs.rust-analyzer}/bin"%,
      },
    },
  },

  GoShell = BashShell & {
    inputs_spec = {
      go.input | default = "nixpkgs",
      gopls.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        go = nix-s%"%{inputs.go}/bin"%,
        gopls = nix-s%"%{inputs.gopls}/bin"%,
      },
    },
  },

  ClojureShell = BashShell & {
    inputs_spec = {
      clojure.input | default = "nixpkgs",
      clojure-lsp.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        clojure = nix-s%"%{inputs.clojure}/bin"%,
        clojure-lsp = nix-s%"%{inputs.clojure-lsp}/bin"%,
      },
    },
  },

  CShell = BashShell & {
    inputs_spec = {
      clang.input | default = "nixpkgs",
      clang-tools.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        clang = nix-s%"%{inputs.clang}/bin"%,
        clang-tools = nix-s%"%{inputs.clang-tools}/bin"%,
      },
    },
  },

  # intelephense is currently broken in nixpkgs
  PhpShell = BashShell & {
    inputs_spec = {
      php.input | default = "nixpkgs",
      intelephense = {
        path = "nodePackages"."intelephense",
        input | default = "nixpkgs",
      },
    },
    inputs,

    output.structured_env = {
      PATH = {
        php = nix-s%"%{inputs.php}/bin"%,
        intelephense = nix-s%"%{inputs.intelephense}/bin"%,
      },
    },
  },

  ZigShell = BashShell & {
    inputs_spec = {
      zig.input | default = "nixpkgs",
      zls.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        zig = nix-s%"%{inputs.zig}/bin"%,
        zls = nix-s%"%{inputs.zls}/bin"%,
      },
    },
  },

  # nodePackages_latest.typescript-language-server is marked broken in nixpkgs
  JavascriptShell = BashShell & {
    inputs_spec = {
      nodejs.input | default = "nixpkgs",
      typescript-language-server = {
        path = "nodePackages_latest.typescript-language-server",
        input | default = "nixpkgs",
      }
    },
    inputs,

    output.structured_env = {
      PATH = {
        nodejs = nix-s%"%{inputs.nodejs}/bin"%,
        ts-lsp = nix-s%"%{inputs.typescript-language-server}/bin"%,
      },
    },
  },

  RacketShell = BashShell & {
    inputs_spec = {
      racket.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        racket = nix-s%"%{inputs.racket}/bin"%,
      },
    },
  },

  ScalaShell = BashShell & {
    inputs_spec = {
      scala.input | default = "nixpkgs",
      metals.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        scala = nix-s%"%{inputs.scala}/bin"%,
        metals = nix-s%"%{inputs.metals}/bin"%,
      },
    },
  },

  # broken: PyLTI-0.7.0 not supported for interpreter python3.10
  # works with a regular nix shell though
  Python310Shell = BashShell & {
    inputs_spec = {
      python310.input | default = "nixpkgs",
      python-lsp-server = {
        path = "python310Packages.python-lsp-server",
        input | default = "nixpkgs",
      }
    },
    inputs,

    output.structured_env = {
      PATH = {
        python = nix-s%"%{inputs.python310}/bin"%,
        python-lsp = nix-s%"%{inputs.python-lsp-server}/bin"%,
      },
    },
  },

  ErlangShell = BashShell & {
    inputs_spec = {
      erlang.input | default = "nixpkgs",
      erlang-ls.input | default = "nixpkgs",
    },
    inputs,

    output.structured_env = {
      PATH = {
        erlang = nix-s%"%{inputs.erlang}/bin"%,
        erlang-lsp = nix-s%"%{inputs.erlang-ls}/bin"%,
      },
    },
  },
}
