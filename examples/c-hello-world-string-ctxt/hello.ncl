{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    gcc = { input = "nixpkgs" },
    hello = {
      input = "sources",
      path = "hello.c",
    },
  }

  , output = fun { inputs, nix, .. } =>
    {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = nix.lib.nix_string_hack [inputs.bash, "/bin/bash"],
        args = [ "-c",
          ([inputs.gcc, "/bin/gcc ", inputs.hello, " -o hello\n"]
           @ [ inputs.coreutils, "/bin/mkdir -p $out/bin\n"]
           @ [ inputs.coreutils, "/bin/cp hello $out/bin/hello"])
           |> nix.lib.nix_string_hack
        ]
      },
      env = {},
    } | nix.builders.NickelPkg
}
