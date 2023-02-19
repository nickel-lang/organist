{
  inputs_spec = {
    bash = { input = "nixpkgs" },
    coreutils = { input = "nixpkgs" },
  },

  # parameters
  inputs,
  nix,

  output =
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
        %{inputs.coreutils}/bin/cp %{nix.lib.import_file "naked-stdenv.sh"} $target
      "%,
      ],
    },
  } | nix.builders.NickelPkg
}
