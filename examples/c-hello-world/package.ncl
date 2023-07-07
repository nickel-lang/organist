let builders = (import "./nickel.lock.ncl").nickel-nix.builders in

builders.NixpkgsPkg & {
  inputs_spec = {
    bash.input = "nixpkgs",
    coreutils.input = "nixpkgs",
    gcc.input = "nixpkgs",
    hello = {
      input = "sources",
      path = "hello.c",
    },
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
          gcc %{inputs.hello.outputPath} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "%,
      },
    }
}
