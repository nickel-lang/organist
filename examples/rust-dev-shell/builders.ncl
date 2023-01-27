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
      PATH = [
        s%"%{inputs.bash}/bin"%,
        s%"%{inputs.cargo}/bin"%,
        s%"%{inputs.rustc}/bin"%,
        s%"%{inputs.rustfmt}/bin"%,
        s%"%{inputs.rust-analyzer}/bin"%
      ],
    },
    output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" xs) output.structured_env,
  },
}
