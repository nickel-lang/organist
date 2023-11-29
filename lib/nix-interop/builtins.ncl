let derivations = import "derivation.ncl" in
{
  import_file
    | String -> derivations.NixPath
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
  import_nix
    | doc m%%"
      Import a Nix value from one of the flake inputs.
      The value should be passed in a flakeref-like format
      `input_name#attribute_path`.

      # Example

      ```nickel
      cmd = nix-s%"%{import_nix "nixpkgs#hello"}/bin/hello > $out"%
      ```
    "%%
    | derivations.NixInputSugar -> derivations.NixInput
    = fun x => x,
  builtin
    | doc m%"
      Apply an arbitrary Nix builtin to the given arguments.
    "%
    | String -> Dyn -> derivations.NixBuiltinCall
    = fun _name _arg => { name = _name, arg = _arg },
  placeholder
    | doc m%"
      Return a placeholder string for the specified output that will be
      substituted by the corresponding output path at build time.

      Wrapper around the Nix
      [placeholder](https://nixos.org/manual/nix/stable/language/builtins.html#builtins-placeholder)
      builtin.
    "%
    | String -> derivations.NixBuiltinCall
    = fun _output => { name = "placeholder", args = _output },
  to_file
    | doc m%"
      Store the string s in a file in the Nix store and return its path.
      The file has suffix name.

      Wrapper around the Nix
      [toFile](https://nixos.org/manual/nix/stable/language/builtins.html#builtins-toFile)
      builtin.
    "%
    | String -> derivations.NixString -> derivations.NixToFile
    = fun _name _text => { name = _name, text = _text },
}
