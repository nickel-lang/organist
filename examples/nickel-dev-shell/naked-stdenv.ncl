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
      cmd = s%"%{inputs.bash}/bin/bash"%,
      args = [
      "-c",
      s%"
        %{inputs.coreutils}/bin/mkdir -p $out
        target=$out/setup
        %{inputs.coreutils}/bin/touch $target
        %{inputs.coreutils}/bin/cp %{inputs.naked-stdenv} $target
      "%,
      ],
    },
    env = {},
  } | nix.builders.NickelPkg
}
