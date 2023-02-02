{
  inputs_spec = {
    bash.input = "nixpkgs",
    coreutils.input = "nixpkgs",
    gcc.input = "nixpkgs",
  }

  , output = fun { inputs, nix, .. } =>
    {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = nix-s%"%{inputs.bash}/bin/bash"%,
        args = [ "-c",
          nix-s%"
            %{inputs.gcc}/bin/gcc %{nix.lib.import_file "hello.c"} -o hello
            %{inputs.coreutils}/bin/mkdir -p $out/bin
            %{inputs.coreutils}/bin/cp hello $out/bin/hello
           "%
        ]
      },
      env = {},
    } | nix.builders.NickelPkg
}
