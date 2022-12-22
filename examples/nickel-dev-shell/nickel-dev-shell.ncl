{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    nakedStdenv = { input = "myInputs" },
  },

  output = fun { inputs, nix, .. } =>
  {
    name = "nickel-shell",
    version = "0.1",
    build_command = {
      cmd = s%"%{inputs.bash}/bin/bash"%,
      args = [],
    },
    env = {
      stdenv = inputs.nakedStdenv,
    },
  } | nix.builders.NickelPkg
}
