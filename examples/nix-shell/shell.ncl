{
  inputs_spec = {
    hello = { input = "nixpkgs" },
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
  }

  , output = fun { inputs, nix, .. } =>
    let builders = import "../builders.ncl" in
    let hello = {
      name = "hello",
      version = "0.1",
      build_command = {
        cmd = "%{inputs.bash}/bin/bash",
        args = [ "-c", m%"
          %{inputs.coreutils}/bin/mkdir -p $out/bin
          %{inputs.coreutils}/bin/cat <<EOF > $out/bin/hello
            #!%{inputs.bash}/bin/bash
            echo "Hello world"
          EOF
        "%m, ]
      },
      env = {},
      dependencies = [ inputs.bash, inputs.coreutils ],
    } | builders.NickelPkg
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

    } | nix.Shell,
}
