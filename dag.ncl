let DagElement = fun Data => {
    before : Array Str | default = [],
    after : Array Str | default = [],
    value : Data
}
in

let Dag = fun Data => {
        _: DagElement Data
    }
in

let topo_sort
  | Dag Str -> Array Str
  = fun dag => dag
    |> record.values
    |> array.map (fun elt => elt.value)
in

let StructuredEnvVar = {sep : Str | default = ":", elems : Dag Str} in
let StructuredEnv = { _ : StructuredEnvVar } in
let Env = { _ : Str } in

let destructure_env_elt
  | Str -> StructuredEnvVar -> Str
  = fun name { sep, elems } =>
    elems
    |> topo_sort
    |> string.join sep
in

let destructure_env
  | StructuredEnv -> Env
  = record.map destructure_env_elt
in

{
    env | Env = destructure_env structured_env,

    # Building the DAG in client code. This is so nice because it composes well,
    # but it's also quite heavy to write
    structured_env | StructuredEnv = {
      PATH.elems = {
        bash.value = "$bash/bin",
        gcc.value = "$gcc/bin",
        clang.value = "$clang/bin",
        clang.before = ["gcc"],
      },
    },

    # Would be nice to be able to just write (for the simple cases)
    # something like
    # ```
    # structured_env.PATH | ListPath = [ "${bash}/bin", "$clang/bin", "$gcc/bin" ],
    # dependencies | NamedPath = [ bash, clang, gcc ], # Make *.pname the keys
    # dependencies | NamedDeps = [ deps.bash, deps.clang, deps.gcc ],
    # ```
    # which would expand to
    # ```
    # Structured_env.PATH.elems = {
    #  "$bash/bin" = { value = "$bash/bin", before = ["$clang/bin"], },
    #  "$clang/bin" = { value = "$clang/bin", before = ["$gcc/bin"], },
    #  "$gcc/bin" = { value = "$gcc/bin", },
    # },
}
