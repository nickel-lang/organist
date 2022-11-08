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
        cmd = "%{inputs.bash.outputPath}/bin/bash",
        args = [ "-c", m%"
          %{inputs.gcc.outputPath}/bin/gcc %{inputs.hello.outputPath} -o hello
          %{inputs.coreutils.outputPath}/bin/mkdir -p $out/bin
          %{inputs.coreutils.outputPath}/bin/cp hello $out/bin/hello
        "%m, ]
      },
      env = {},
      dependencies = [ inputs.bash, inputs.coreutils, inputs.gcc, inputs.hello ],
    } | nix.builders.NickelPkg
}
