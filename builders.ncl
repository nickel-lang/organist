let { NickelDerivation, Derivation, .. } = import "contracts.ncl" in

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
          cmd = nix-s%"%{inputs.nixpkgs.bash}/bin/bash"%,
          args = [ "-c",
            nix-s%"
              %{inputs.nixpkgs.gcc}/bin/gcc %{nix.lib.import_file "hello.c"} -o hello
              %{inputs.nixpkgs.coreutils}/bin/mkdir -p $out/bin
              %{inputs.nixpkgs.coreutils}/bin/cp hello $out/bin/hello
             "%
          ]
        },
        env = {},
      } | nix.builders.NickelPkg
      ```
      "%%%
    = NickelDerivation,

  BashShell = {
    inputs_spec = {},
    inputs,

    output =
      {
        version | default = "0.1",

        # This is required otherwise nix develop will fail with a message that it
        # only supports bash.
        build_command = {
          cmd = nix-s%"%{inputs.nixpkgs.bash}/bin/bash"%,
          args = [],
        },

        structured_env = {
          # TODO: handle naked derivations without having to interpolate
          stdenv.naked_std_env = nix-s%"%{inputs.nickel-nix-internals.naked_std_env}"%,
        },

        packages = { bash = inputs.nixpkgs.bash },

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
      } | (NickelPkg & { packages | { _ : Derivation } }),
  },

  RustShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        cargo = inputs.nixpkgs.cargo,
        rustc = inputs.nixpkgs.rustc,
        rustfmt = inputs.nixpkgs.rustfmt,
        rust-analyzer = inputs.nixpkgs.rust-analyzer,
      },
    },

  GoShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        go = inputs.nixpkgs.go,
        gopls = inputs.nixpkgs.gopls,
      },
    },

  ClojureShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        clojure = inputs.nixpkgs.clojure,
        clojure-lsp = inputs.nixpkgs.clojure-lsp,
      },
    },

  CShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        clang = inputs.nixpkgs.clang,
        clang-tools = inputs.nixpkgs.clang-tools,
      },
    },

  # intelephense is currently broken in nixpkgs
  PhpShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        php = inputs.nixpkgs.php,
        intelephense = inputs.nixpkgs.nodePackages.intelephense,
      },
    },

  ZigShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        zig = inputs.nixpkgs.zig,
        zls = inputs.nixpkgs.zls,
      },
    },

  # nodePackages_latest.typescript-language-server is marked broken in nixpkgs
  JavascriptShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        nodejs = inputs.nixpkgs.nodejs,
        ts-lsp = inputs.nixpkgs.nodePackages_latest.typescript-language-server,
      },
    },

  RacketShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        racket = inputs.nixpkgs.racket,
      },
    },

  ScalaShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        scala = inputs.nixpkgs.scala,
        metals = inputs.nixpkgs.metals,
      },
    },

  # broken: PyLTI-0.7.0 not supported for interpreter python3.10
  # works with a regular nix shell though
  Python310Shell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        python = inputs.nixpkgs.python310,
        python-lsp = inputs.nixpkgs.python310Packages.python-lsp-server,
      },
    },

  ErlangShell =
    BashShell
    & {
      inputs_spec = {},
      inputs,

      output.packages = {
        erlang = inputs.nixpkgs.erlang,
        erlang-lsp = inputs.nixpkgs.erlang-ls,
      },
    },

  HaskellStackShell =
    BashShell
    & {
      ghcVersion, # User-defined. To keep in sync with the one used by stack
      inputs_spec = {
        # This will point to a copy of nixpkgs in nix store
        path = {},
      },
      inputs,

      output.packages =
        let stack-wrapped =
          {
            name = "stack-wrapped",
            version = inputs.nixpkgs.stack.version,
            build_command = {
              cmd = nix-s%"%{inputs.nixpkgs.bash}/bin/bash"%,
              args = [
                "-c",
                # Sorry about Topiary formatting of the following lines
                nix-s%"
            export PATH="%{inputs.nixpkgs.coreutils}/bin:$PATH"
            mkdir -p $out/bin
            echo "$0" > $out/bin/stack
            chmod a+x $out/bin/*
          "%,
                nix-s%"
            #!%{inputs.nixpkgs.bash}/bin/bash
            %{inputs.nixpkgs.stack}/bin/stack \
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
          stack' = inputs.nixpkgs.stack,
          ormolu = inputs.nixpkgs.ormolu,
          nix = inputs.nixpkgs.nix,
          git = inputs.nixpkgs.git,
          haskell-language-server = inputs.nixpkgs.haskell.packages."ghc%{ghcVersion}".haskell-language-server,
        },
    },
}
