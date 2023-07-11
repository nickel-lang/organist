let nickel-nix = (import "./nickel.lock.ncl").nickel-nix in

nickel-nix.builders.NixpkgsPkg & {
  inputs_spec = {
    bash.input = "nixpkgs",
    coreutils.input = "nixpkgs",
    gcc.input = "nixpkgs",
  },

  inputs,

  output =
    {
      name = "hello",
      version = "0.1",
      structured_env = {
        buildInputs.gcc = inputs.gcc,
        buildInputs.coreutils = inputs.coreutils,
        buildInputs.bash = inputs.bash,
      },
      env = {
        buildCommand = nix-s%"
          gcc %{nickel-nix.nix.lib.import_file "hello.c"} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "%,
      },
    }
}
