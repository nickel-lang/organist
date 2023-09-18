let contracts = import "contracts.ncl" in
{
  import_file
    | String -> contracts.NixPath
    | doc m%%"
          Take a path as a string and produce a Nix path, which will be
          interpreted as a path on the Nix side and added to the store.

          # Example

          ```nickel
          cmd = s%"
              %{inputs.gcc}/bin/gcc %{import_file "hello.c"} -o hello
              %{inputs.coreutils}/bin/mkdir -p $out/bin
              %{inputs.coreutils}/bin/cp hello $out/bin/hello
             "%,
          ```
        "%%
    = fun filepath => { path = filepath },
  import_nix | contracts.NixInputSugar -> contracts.NixInput
    = fun x => x,
  placeholder | String -> contracts.NixPlaceholder
    = fun _output => { output = _output }
}
