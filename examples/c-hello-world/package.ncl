let nickel-nix = (import "./nickel.lock.ncl").nickel-nix in

nickel-nix.builders.NixpkgsPkg & {
  output =
    {
      name = "hello",
      version = "0.1",
      structured_env = {
        buildInputs.gcc = nickel-nix.lib.import_nix "nixpkgs#gcc",
        buildInputs.coreutils = nickel-nix.lib.import_nix "nixpkgs#coreutils",
        buildInputs.bash = nickel-nix.lib.import_nix "nixpkgs#bash",
      },
      env = {
        buildCommand = nix-s%"
          gcc %{nickel-nix.lib.import_file "hello.c"} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "%,
      },
    }
}
