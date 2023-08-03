let inputs = import "./nickel.lock.ncl" in
let nickel-nix = inputs.nickel-nix in

nickel-nix.builders.NixpkgsPkg & {
  output =
    {
      name = "hello",
      version = "0.1",
      nix_drv = {
        buildInputs.gcc = nickel-nix.lib.import_nix "nixpkgs#gcc",
        buildInputs.coreutils = nickel-nix.lib.import_nix "nixpkgs#coreutils",
        buildInputs.bash = nickel-nix.lib.import_nix "nixpkgs#bash",
        buildCommand = nix-s%"
          gcc %{nickel-nix.lib.import_file "hello.c"} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "% | nickel-nix.contracts.NixString,
      },
    }
}
