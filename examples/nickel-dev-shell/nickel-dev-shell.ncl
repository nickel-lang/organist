{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    nakedStdenv = { input = "myInputs" },
  },

  # On Nix side:
  # inputs = { coreutils = inputs.nixpkgs.legacyPackages.x86_64-linux.coreutils.drvPath; }

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
