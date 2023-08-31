let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  packages."default" = packages.hello,
  packages.hello =
    organist.builders.NixpkgsPkg
    & {
      name = "hello",
      version = "0.1",
      nix_drv = {
        buildInputs.gcc = organist.lib.import_nix "nixpkgs#gcc",
        buildInputs.coreutils = organist.lib.import_nix "nixpkgs#coreutils",
        buildInputs.bash = organist.lib.import_nix "nixpkgs#bash",
        buildCommand =
          nix-s%"
          gcc %{organist.lib.import_file "hello.c"} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "% | organist.contracts.NixString,
      },
    }
}
