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
