{
  inputs_spec = {
    hello = { input = "nixpkgs" },
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
  }

  , output = fun { inputs, nix, .. } =>
    let hello = {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = "%{inputs.bash.outputPath}/bin/bash",
        args = [ "-c", m%"
          %{inputs.coreutils.outputPath}/bin/mkdir -p $out/bin
          %{inputs.coreutils.outputPath}/bin/cat <<EOF > $out/bin/hello
          #!%{inputs.bash.outputPath}/bin/bash
          echo "Hello world"
          EOF
          %{inputs.coreutils.outputPath}/bin/chmod +x $out/bin/hello
        "%m, ]
      },
      env = {},
      dependencies = [ inputs.bash, inputs.coreutils ],
    } | nix.builders.NickelPkg
    in
    {
       name = "hello"

       , packages = [
         hello
       ]

       , shellHook = m%"
           echo 'Development shell'
           hello
         "%m

    } | nix.builders.NickelShell,
}
