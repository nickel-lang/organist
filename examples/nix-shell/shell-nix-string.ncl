{
  inputs = {
    hello = { input = "nixpkgs" }
    , cowsay = { input = "nixpkgs" }
  }

  , output = fun { pkgs, nix, .. } =>
    {
       name = "hello"

       , packages = [
         pkgs.hello
       ]

       , shellHook = nix.lib.nix_string_hack [
          pkgs.cowsay, "/bin/cowsay 'Welcowme to this nickel-powered shell!'",
       ]

} | nix.Shell
}
