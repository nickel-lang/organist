{
  inputs_spec = {
    hello = { input = "nixpkgs" }
    , cowsay = { input = "nixpkgs" }
  }

  , output = fun { inputs, nix, .. } =>
    {
       name = "hello"

       , packages = [
         inputs.hello
       ]

       , shellHook = nix.lib.nix_string_hack [
          inputs.cowsay, "/bin/cowsay 'Welcowme to this nickel-powered shell!'",
       ]

} | nix.Shell
}
