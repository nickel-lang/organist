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
          cmd = s%"%{inputs.bash}/bin/bash"%,
          args = [ "-c",
            s%"
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
        nakedStdenv.input | priority -100 = "myInputs",
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
        cmd = s%"%{inputs.bash}/bin/bash"%,
        args = [],
      },

      env = {
        # TODO: handle naked derivations without having to interpolate
        stdenv = s%"%{inputs.nakedStdenv}"%,
      },
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
        bash = s%"%{inputs.bash}/bin"%,
        cargo = s%"%{inputs.cargo}/bin"%,
        rustc = s%"%{inputs.rustc}/bin"%,
        rustfmt = s%"%{inputs.rustfmt}/bin"%,
        rust-analyzer = s%"%{inputs.rust-analyzer}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        go = s%"%{inputs.go}/bin"%,
        gopls = s%"%{inputs.gopls}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        clojure = s%"%{inputs.clojure}/bin"%,
        clojure-lsp = s%"%{inputs.clojure-lsp}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        clang = s%"%{inputs.clang}/bin"%,
        clang-tools = s%"%{inputs.clang-tools}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        php = s%"%{inputs.php}/bin"%,
        intelephense = s%"%{inputs.nodePackages_latest.intelephense}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        zig = s%"%{inputs.zig}/bin"%,
        zls = s%"%{inputs.zls}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        nodejs = s%"%{inputs.nodejs}/bin"%,
        ts-lsp = s%"%{inputs.nodePackages_latest.typescript-language-server}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },

  RacketShell = BashShell & {
    inputs_spec | {
      racket.input | priority -100 = "nixpkgs",
      ..
    },
    inputs,
    output.structured_env = {
      PATH = {
        bash = s%"%{inputs.bash}/bin"%,
        racket = s%"%{inputs.racket}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        scala = s%"%{inputs.scala}/bin"%,
        metals = s%"%{inputs.metals}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        python = s%"%{inputs.python310}/bin"%,
        python-lsp = s%"%{inputs.python310Packages.python-lsp-server}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
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
        bash = s%"%{inputs.bash}/bin"%,
        erlang = s%"%{inputs.erlang}/bin"%,
        erlang-lsp = s%"%{inputs.erlang-ls}/bin"%,
      },
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" (record.values xs)) output.structured_env,
  },

}
