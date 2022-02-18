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

       , shellHook = nix.lib.nix_string_hack [
          "echo 'Development shell'",
          pkgs.hello,
          "/bin/hello"
       ]
    } | nix.Shell,
}
