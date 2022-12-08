{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
  },

  output = fun { inputs, nix, .. } =>
  {
    name = "nickel-shell",
    version = "0.1",
    builder = "%{inputs.bash.outputPath}/bin/bash",
  }
}
