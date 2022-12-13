{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    nakedStdenv = { input = "myInputs" },
  },

  output = fun { inputs, nix, .. } =>
  {
    name = "nickel-shell",
    version = "0.1",
    build_command = {
      cmd = "%{inputs.bash.outputPath}/bin/bash",
      args = [],
    },
    dependencies = [ inputs.bash ],
    env = {
      stdenv = inputs.nakedStdenv,
    },
  } | nix.builders.NickelPkg
}
