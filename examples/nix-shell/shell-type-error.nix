{ pkgs ? import <nixpkgs> {}
}:

pkgs.mkShell {
  name = "hello";
  packages = "pkgs.hello";
  shellHook = ''
    echo "Development shell"
    ${pkgs.hello}/bin/hello
  '';
}
