let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression
& {
  Schema,
  config | Schema
    = {
      packages."default" = packages.hello,
      packages.hello =
        organist.nix.builders.NixpkgsPkg
        & {
          name = "hello",
          version = "0.1",
          structured_env.buildInputs = {
            gcc = organist.import_nix "nixpkgs#gcc",
            coreutils = organist.import_nix "nixpkgs#coreutils",
            bash = organist.import_nix "nixpkgs#bash",
          },
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
      shells.build.packages.hello = packages.hello,
    },
} | organist.modules.T
