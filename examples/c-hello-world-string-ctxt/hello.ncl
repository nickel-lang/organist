{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    gcc = { input = "nixpkgs" },
    hello = { input = "sources" },
  }

  , output = fun { inputs, nix, .. } =>
    {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = nix.lib.nix_string_hack [inputs.bash, "/bin/bash"],
        args = [ "-c",
          nix.lib.nix_string_hack [
             inputs.gcc,
             "/bin/gcc ",
             inputs.hello,
             " -o hello\n"]
           @ [
             inputs.coreutils,
             "/bin/mkdir -p $out/bin\n"]
           @ [
             inputs.coreutils,
             "/bin/cp hello $out/bin/hello"]
        ]
      },
      env = {},
    } | nix.builders.NickelPkg
}
