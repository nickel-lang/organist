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
      # default or not?
      bash.input | default = "nixpkgs",
      nakedStdenv.input | default = "myInputs",
    },

    inputs,

    output = {
      version | default = "0.1",

      # this is required otherwise nix develop
      # will fail with a message that it only supports bash
      build_command = {
        cmd = nix-s%"%{inputs.bash}/bin/bash"%,
        args = [],
      },

      env = {
        # TODO: handle naked derivations without having to interpolate
        stdenv = nix-s%"%{inputs.nakedStdenv}"%,
        bash = nix-s%"%{inputs.bash}/bin"%,
      },
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },

  # intelephense is currently broken in nixpkgs
  PhpShell = BashShell & {
    inputs_spec = {
      php.input | default = "nixpkgs",
      nodePackages.intelephense.input | default = "nixpkgs",
    },

    inputs,
    output.structured_env = {
      PATH = {
        php = nix-s%"%{inputs.php}/bin"%,
        intelephense = nix-s%"%{inputs.nodePackages_latest.intelephense}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },

  # nodePackages_latest.typescript-language-server is marked broken in nixpkgs
  JavascriptShell = BashShell & {
    inputs_spec = {
      nodejs.input | default = "nixpkgs",
      nodePackages_latest.typescript-language-server.input | default = "nixpkgs",
    },

    inputs,
    output.structured_env = {
      PATH = {
        nodejs = nix-s%"%{inputs.nodejs}/bin"%,
        ts-lsp = nix-s%"%{inputs.nodePackages_latest.typescript-language-server}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },

  # broken: PyLTI-0.7.0 not supported for interpreter python3.10
  # works with a regular nix shell though
  Python310Shell = BashShell & {
    inputs_spec = {
      python310.input | default = "nixpkgs",
      python310Packages.python-lsp-server.input | default = "nixpkgs",
    },

    inputs,
    output.structured_env = {
      PATH = {
        python = nix-s%"%{inputs.python310}/bin"%,
        python-lsp = nix-s%"%{inputs.python310Packages.python-lsp-server}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
    output.env = record.map (fun _n xs => array.foldl (fun acc x => nix-s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },
}
