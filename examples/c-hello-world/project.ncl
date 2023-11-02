let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  packages."default" = packages.hello,
  packages.hello =
    organist.nix.builders.NixpkgsPkg
    & {
      name = "hello",
      version = "0.1",
      nix_drv = {
        buildInputs.gcc = organist.import_nix "nixpkgs#gcc",
        buildInputs.coreutils = organist.import_nix "nixpkgs#coreutils",
        buildInputs.bash = organist.import_nix "nixpkgs#bash",
        buildCommand =
          nix-s%"
          gcc %{organist.nix.builtins.import_file "hello.c"} -o hello
          mkdir -p $out/bin
          cp hello $out/bin/hello
        "%
            | organist.nix.derivation.NixString,
      },
    },

  shells = organist.shells.Bash,
  shells.build.packages.hello = packages.hello,
} | organist.OrganistExpression
