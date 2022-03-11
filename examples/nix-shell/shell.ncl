# Same as shell.ncl, but use `nix_string_hack` to preserve Nix string contexts.
# This is for illustration purpose, and not really useful in this particular
# example.
{
  inputs_spec = {
    hello = { input = "nixpkgs" }
  }

  , output = fun { inputs, nix, .. } =>
    {
       name = "hello"

       , packages = [
         inputs.hello
       ]

       , shellHook = m%"
           echo 'Development shell'
           hello
         "%m

    } | nix.Shell,
}
