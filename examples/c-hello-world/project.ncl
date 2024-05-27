let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  flake.packages."default" = flake.packages.hello,
  flake.packages.hello =
    organist.nix.builders.NixpkgsPkg
    & {
      name = "hello",
      version = "0.1",
      structured_env.buildInputs = { gcc, coreutils, bash } | organist.nix.builtins.NixpkgsDerivations,
      env.src = organist.nix.builtins.import_file ".",
      env.buildCommand =
        nix-s%"
          cp $src/* .
          mkdir -p $out/{include,lib}
          gcc -shared hello.c -o libhello.so
          cp *.so $out/lib/
          cp hello.h $out/include/hello.h
        "%
          | organist.nix.derivation.NixString,
    },

  shells = organist.shells.Bash,
  shells.build.packages.hello = flake.packages.hello,
} | organist.OrganistExpression
