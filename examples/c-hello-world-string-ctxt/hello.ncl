{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    gcc = { input = "nixpkgs" },
    # hello = {
    #   input = "sources",
    #   path = "hello.c",
    # },
  }

  , output = fun { inputs, nix, .. } =>
    {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = s%"%{inputs.bash}/bin/bash"%,
        args = [ "-c",
          s%"
            %{inputs.gcc}/bin/gcc %{nix.lib.import_file "hello.c"} -o hello
            %{inputs.coreutils}/bin/mkdir -p $out/bin
            %{inputs.coreutils}/bin/cp hello $out/bin/hello
           "%
        ]
      },
      env = {},
    } | nix.builders.NickelPkg
}
