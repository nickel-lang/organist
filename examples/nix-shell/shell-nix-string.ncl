# Same as shell.ncl, but use `nix_string_hack` to preserve Nix string contexts.
# This is for illustration purpose, and not really useful in this particular
# example.
{
  inputs = {
    hello = { input = "nixpkgs" }
  }

  , output = fun { pkgs, nix, .. } =>
    { # (optional) name of the shell
       name = "hello"

       , packages = [
         pkgs.hello
       ]

       , shellHook = m%"
           echo 'Development shell'
           hello
         "%m

    } | nix.Shell,
}
