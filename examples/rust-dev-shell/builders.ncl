let {NickelDerivation, NixString, Derivation, ..} = import "contracts.ncl" in

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

  env_lib = {
    DagElement = fun Data => {
      before : Array Str | default = [],
      after : Array Str | default = [],
      value : Data
    },

    Dag = fun Data => {
          _: DagElement Data
    },

    topo_sort
      | Dag Dyn -> Array Dyn
      = fun dag => dag
        |> record.values
        |> array.map (fun elt => elt.value),

    StructuredEnvVar = {sep : Str | default = ":", elems : Dag NixString},
    StructuredEnv = { _ : StructuredEnvVar },
    Env = { _ : NixString },

    join_path | Str -> Array NixString -> NixString
      = fun sep arr =>
      if array.length arr == 0 then
        ""
      else
        array.foldl
          (fun acc path_elem => s%"%{acc}%{sep}%{path_elem}"%)
          (array.head arr)
          (array.tail arr),

    destructure_env_elt
      | Str -> StructuredEnvVar -> NixString
      = 
        fun name { sep, elems } =>
        elems
        |> topo_sort
        |> join_path sep,

    destructure_env
      | StructuredEnv -> Env
      = record.map destructure_env_elt,

    from_drv_array
      | Array Derivation -> StructuredEnvVar
      = array.foldl (fun acc elt => acc & {elems."%{elt.name}".value = elt})
        {elems = {}},

    bins_from_drvs
      | Array Derivation -> StructuredEnvVar
      = array.foldl
        (fun acc drv => acc & {elems."%{drv.name}".value = s%"%{drv}/bin"%})
        {elems = {}},
  }, 

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

      build_command = {
        cmd = s%"%{inputs.bash}/bin/bash"%,
        args = [],
      },

      env | env_lib.Env = env_lib.destructure_env structured_env,

      # Building the DAG in client code. This is so nice because it composes well,
      # but it's also quite heavy to write
      structured_env | env_lib.StructuredEnv = {
        stdenv.elems = {
          stdenv.value = s%"%{inputs.nakedStdenv}"%,
        },
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

    output.structured_env.PATH = env_lib.bins_from_drvs [
      inputs.bash,
      inputs.cargo,
      inputs.rustc,
      inputs.rustfmt,
      inputs.rust-analyzer
    ],
    # output.structured_env = {
    #   PATH = env.from_drv_array [
    #     s%"%{inputs.bash}/bin"%,
    #     s%"%{inputs.cargo}/bin"%,
    #     s%"%{inputs.rustc}/bin"%,
    #     s%"%{inputs.rustfmt}/bin"%,
    #     s%"%{inputs.rust-analyzer}/bin"%
    #   ],
    # },
    # output.env = record.map (fun _n xs => array.foldl (fun acc x => s%"%{acc}:%{x}"%) "" xs) output.structured_env,
  },
}
