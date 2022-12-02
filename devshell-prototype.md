```
fun { pkgs, .. } =>
{
    inputs = {
        gcc =  pkgs.gcc
    }
} | DevShell
```

```
fun { pkgs, .. } =>
{
    ecosystems.C-gcc.enable = true,
    ecosystems.rust.enable = true,
    inputs =
```


```
({
  inputs_spec = ...,
  
  inputs | .... = {
    gcc | force = ...,
  },
  
  output = {
    # custom outputs
  }
} | DevShell) & ecosystems.C-gcc & ecosystems.rust
```

ecosystems.C-gcc ShellPlugin

{ plugin.cgcc = {inputs = .., output = ..}}

inputs.gcc.ouputPath

inputs.foobar.outputPath

extractInputs

nixPackage "nixpkgs#gcc" => {type = `NixDerivation}

```
ecosystems.C-gcc & {inputs.gcc = foobar}
```

```
ecosystems.C-gcc = {
    # enable | default = true,
    gcc = nixPackage "gcc-7",
    gccWrapper = writeScript "gcc" "exec gcc \$@\"n
    shellPackages.gcc = gccWrapper,
}
```

Shell schema?

```
{
    RawShell = {
        name : Str | default = "nickel-shell",
        env : { _: Str } | default = {},
        shell_hook : Str | default = "",
    },
    Shell = RawShell & {
        init_scripts : Dag Str | default = {}, 
        structured_env : { _ : { sep : Str | default = ":", elems : Dag Str }},
        
        shell_hook = evaluate_dag init_scripts,
        env = record.map (fun name { sep, elems } => string.join sep (record.values elems)) structured_env,
    },
    
    ShellWithProgs = Shell & {
        programs = { _: { path : Str, description: Str },
        
        structured_env.PATH.elems = dag.from_record programs,
        
        init_scripts.describe_available_tools.value =
            string.join "\n" record.values (record.map (fun name { description, ..} => "%{name}: %{description}") programs),
    },
    Dag = fun Data => {
        _: {
            before : Array Str | default = [],
            after : Array Str | default = [],
            value : Data
        },
    },
    
    bash_env | Shell = {
        structured_env.PATH.elems.bash.value = pkgs.bash,
    },
    
    c_gcc_env | Shell = {
        structured_env.PATH.elems.gcc.value = pkgs.gcc,
        
        structured_env.LD_LIBRARY_PATH.elems = dag.map (fun library => library ++ "/lib") c_libraries,
        structured_env.INCLUDE_PATH.elems = dag.map (fun library => library ++ "/include") c_libraries,
        
        c_libraries : Dag Str,
    },
    
    nickel_env | ShellWithProgs = {
        programs.nickel = { path = "%{pkgs.nickel}/bin/nickel", description = "The config language to rule them all" },
    },
    
    my_nickel_shell = nickel_env & { programs = ... },
    
    my_shell | Shell = bash_env & c_gcc_env & {
        c_libraries = dag.element_at_arbitrary_position_because_i_dont_care pkgs.openssl,
    },
}
```
