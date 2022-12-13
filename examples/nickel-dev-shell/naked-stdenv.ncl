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
        #%{inputs.coreutils.outputPath}/bin/echo -n "test" > $target
      "%m,
      #"%{inputs.coreutils.outputPath}/bin/echo 'hi'"
      #"echo $out",
      #"target=$out/setup",
      #"mkdir -p \"$(dirname \"$target\")\"",
      #"echo -n \"test\" > \"$target\""
      ],
    },
    dependencies = [ inputs.bash, inputs.coreutils, inputs.naked-stdenv ],
    env = {},
  } | nix.builders.NickelPkg
}
