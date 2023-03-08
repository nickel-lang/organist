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
    inputs_spec
      | {
        # default or not?
        bash.input | priority -100 = "nixpkgs",
        naked_std_env.input | priority -100 = "nixel-internals",
        ..
      }
      | default = {},

    inputs,
    nix,

    output = {
      version | default = "0.1",

      # this is required otherwise nix develop
      # will fail with a message that it only supports bash
      build_command = {
        cmd = nix-s%"%{inputs.bash}/bin/bash"%,
        args = [],
      },

      structured_env.stdenv = {
        # TODO: handle naked derivations without having to interpolate
        naked_std_env = nix-s%"%{inputs.naked_std_env}"%,
      },

      # Compute `env` from `structured_env`. Note that thanks to recursive
      # overriding, if stuff is added to `structured_env` through merging,
      # `env` will be automatically up-to-date
      env =
        structured_env
        |> record.map (fun _n xs =>
          # Intersperse ':' between environment variable fragments
          let values = record.values xs in
          let first = array.head values in
          values
          |> array.tail
          |> array.foldl (fun acc value => nix-s%"%{acc}:%{value}"%) first
        ),
    } | NickelPkg,
  },

  RustShell = BashShell & {
    inputs_spec | {
      cargo.input | priority -100 = "nixpkgs",
      rustc.input | priority -100 = "nixpkgs",
      rustfmt.input | priority -100 = "nixpkgs",
      rust-analyzer.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        cargo = nix-s%"%{inputs.cargo}/bin"%,
        rustc = nix-s%"%{inputs.rustc}/bin"%,
        rustfmt = nix-s%"%{inputs.rustfmt}/bin"%,
        rust-analyzer = nix-s%"%{inputs.rust-analyzer}/bin"%,
      },
    },
  },

  GoShell = BashShell & {
    inputs_spec | {
      go.input | priority -100 = "nixpkgs",
      gopls.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        go = nix-s%"%{inputs.go}/bin"%,
        gopls = nix-s%"%{inputs.gopls}/bin"%,
      },
    },
  },

  ClojureShell = BashShell & {
    inputs_spec | {
      clojure.input | priority -100 = "nixpkgs",
      clojure-lsp.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        clojure = nix-s%"%{inputs.clojure}/bin"%,
        clojure-lsp = nix-s%"%{inputs.clojure-lsp}/bin"%,
      },
    },
  },

  CShell = BashShell & {
    inputs_spec | {
      clang.input | priority -100 = "nixpkgs",
      clang-tools.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        clang = nix-s%"%{inputs.clang}/bin"%,
        clang-tools = nix-s%"%{inputs.clang-tools}/bin"%,
      },
    },
  },

  # intelephense is currently broken in nixpkgs
  PhpShell = BashShell & {
    inputs_spec | {
      php.input | priority -100 = "nixpkgs",
      nodePackages.intelephense.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        php = nix-s%"%{inputs.php}/bin"%,
        intelephense = nix-s%"%{inputs.nodePackages_latest.intelephense}/bin"%,
      },
    },
  },

  ZigShell = BashShell & {
    inputs_spec | {
      zig.input | priority -100 = "nixpkgs",
      zls.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        zig = nix-s%"%{inputs.zig}/bin"%,
        zls = nix-s%"%{inputs.zls}/bin"%,
      },
    },
  },

  # nodePackages_latest.typescript-language-server is marked broken in nixpkgs
  JavascriptShell = BashShell & {
    inputs_spec | {
      nodejs.input | priority -100 = "nixpkgs",
      nodePackages_latest.typescript-language-server.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        nodejs = nix-s%"%{inputs.nodejs}/bin"%,
        ts-lsp = nix-s%"%{inputs.nodePackages_latest.typescript-language-server}/bin"%,
      },
    },
  },

  RacketShell = BashShell & {
    inputs_spec | {
      racket.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        racket = nix-s%"%{inputs.racket}/bin"%,
      },
    },
  },

  ScalaShell = BashShell & {
    inputs_spec | {
      scala.input | priority -100 = "nixpkgs",
      metals.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        scala = nix-s%"%{inputs.scala}/bin"%,
        metals = nix-s%"%{inputs.metals}/bin"%,
      },
    },
  },

  # broken: PyLTI-0.7.0 not supported for interpreter python3.10
  # works with a regular nix shell though
  Python310Shell = BashShell & {
    inputs_spec | {
      python310.input | priority -100 = "nixpkgs",
      python310Packages.python-lsp-server.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        python = nix-s%"%{inputs.python310}/bin"%,
        python-lsp = nix-s%"%{inputs.python310Packages.python-lsp-server}/bin"%,
      },
    },
  },

  ErlangShell = BashShell & {
    inputs_spec | {
      erlang.input | priority -100 = "nixpkgs",
      erlang-ls.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        erlang = nix-s%"%{inputs.erlang}/bin"%,
        erlang-lsp = nix-s%"%{inputs.erlang-ls}/bin"%,
      },
    },
  },

  HaskellShell = BashShell & {
    inputs_spec | {
      cabal-install.input | priority -100 = "nixpkgs",
      ghc.input | priority -100 = "nixpkgs",
      haskell-language-server.input | priority -100 = "nixpkgs",
      stack.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = nix-s%"%{inputs.bash}/bin"%,
        cabal-install = nix-s%"%{inputs.cabal-install}/bin"%,
        ghc = nix-s%"%{inputs.ghc}/bin"%,
        haskell-lsp = nix-s%"%{inputs.haskell-language-server}/bin"%,
        stack = nix-s%"%{inputs.stack}/bin"%,
      },
    },
  },
}
