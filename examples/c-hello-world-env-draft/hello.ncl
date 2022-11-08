{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    gcc = { input = "nixpkgs" },
    hello = { input = "sources" },
  }

  , output = fun { inputs | {..}, nix, .. } =>
    let hello_src = nix.callNix "./hello.c" in
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
      env = {
        hello_src = nix.importFile "hello.c"
      },
      dependencies = [ inputs.bash, inputs.coreutils, inputs.gcc, inputs.hello,
hello_src ],
    } | nix.builders.NickelPkg
}
