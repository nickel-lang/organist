{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
    naked-stdenv = {
      input = "sources",
      path = "naked-stdenv.sh",
    },
  },

  output = fun { inputs, nix, .. } =>
  {
    name = "naked-stdenv",
    version = "0.1",
    build_command = {
      cmd = "%{inputs.bash.outputPath}/bin/bash",
      args = [
      "-c",
      m%"
        %{inputs.coreutils.outputPath}/bin/mkdir -p $out
        target=$out/setup
        %{inputs.coreutils.outputPath}/bin/touch $target
        %{inputs.coreutils.outputPath}/bin/cp %{inputs.naked-stdenv.outputPath} $target
      "%m,
      ],
    },
    dependencies = [ inputs.bash, inputs.coreutils, inputs.naked-stdenv ],
    env = {},
  } | nix.builders.NickelPkg
}
