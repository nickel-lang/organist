let contracts = import "contracts.ncl" in

{
  Derivation = contracts.NickelDerivation,
  NickelExpression = contracts.NickelExpression,
  lib = {
    import_file
      | Str -> contracts.NixPath
      | doc m%%"
          Take a path as a string and produce a Nix path, which will be
          interpreted as a path on the Nix side and added to the store.

          # Example

          ```nickel
          cmd = nix-s%"
              %{inputs.gcc}/bin/gcc %{import_file "hello.c"} -o hello
              %{inputs.coreutils}/bin/mkdir -p $out/bin
              %{inputs.coreutils}/bin/cp hello $out/bin/hello
             "%,
          ```
        "%%
      = fun filepath => {path = filepath},
  },
  builders = import "builders.ncl",
}
#TODO: currently, Nickel forbids doc at the toplevel. It's most definitely
# temporary, as the implementation of RFC005 is ongoing. Once the capability is
# restored, remove this message and uncomment the following lines.
#
# | doc m%"
#     Nickel library for Nickel-Nix interoperability. Provide contracts used to
#     serialize Nix inputs to Nickel, to define a Nickel expression, and helpers
#     to build strings which preserves Nix string contexts.
#   "%
