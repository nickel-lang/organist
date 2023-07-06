{
  inputs_spec = {},

  # parameters
  inputs,
  nix,

  output =
    {
      name = "naked-stdenv",
      version = "0.1",
      build_command = {
        cmd = nix-s%"%{inputs.nixpkgs.bash}/bin/bash"%,
        args = [
          "-c",
          nix-s%"
        %{inputs.nixpkgs.coreutils}/bin/mkdir -p $out
        target=$out/setup
        %{inputs.nixpkgs.coreutils}/bin/touch $target
        %{inputs.nixpkgs.coreutils}/bin/cp %{nix.lib.import_file "naked-stdenv.sh"} $target
      "%,
        ],
      },
    } | nix.builders.NickelPkg
}
