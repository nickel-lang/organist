{
  inputs = {
    hello = { input = "nixpkgs" }
  }

  , output = fun { pkgs, nix, .. } =>
    {
       name = "hello"

       , packages = [
         pkgs.hello
       ]

       , shellHook = nix.lib.nix_string_hack [
          "echo 'Development shell'\n",
          pkgs.hello, "/bin/hello",
       ]
    } | nix.Shell,
}
