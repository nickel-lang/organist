{
  inputs_spec = {
    bash.input = "nixpkgs",
    coreutils.input = "nixpkgs",
    gcc.input = "nixpkgs",
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
        cmd = s%"%{inputs.bash.outputPath}/bin/bash"%,
        args = [ "-c",
          s%"
            %{inputs.gcc.outputPath}/bin/gcc %{inputs.hello.outputPath} -o hello
            %{inputs.coreutils.outputPath}/bin/mkdir -p $out/bin
            %{inputs.coreutils.outputPath}/bin/cp hello $out/bin/hello
          "%,
        ]
      },
      env = {},
      dependencies = [ inputs.bash, inputs.coreutils, inputs.gcc, inputs.hello ],
    } | nix.builders.NickelPkg
}
