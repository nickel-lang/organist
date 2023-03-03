let builders = import "builders.ncl" in

{
  inputs_spec = {
    bash.input = "nixpkgs",
    coreutils.input = "nixpkgs",
    gcc.input = "nixpkgs",
    hello = {
      input = "sources",
      path = "hello.c",
    },
  },

  inputs,

  output =
    {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = nix-s%"%{inputs.bash.outputPath}/bin/bash"%,
        args = [ "-c",
          nix-s%"
            %{inputs.gcc.outputPath}/bin/gcc %{inputs.hello.outputPath} -o hello
            %{inputs.coreutils.outputPath}/bin/mkdir -p $out/bin
            %{inputs.coreutils.outputPath}/bin/cp hello $out/bin/hello
          "%,
        ]
      },
      env = {},
      dependencies = [ inputs.bash, inputs.coreutils, inputs.gcc, inputs.hello ],
    } | builders.NickelPkg
}
