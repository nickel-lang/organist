let builders = import "../builders.ncl" in
let nix_builtins = import "../builtins.ncl" in
{
  build =
    builders.Shell
    & {
      packages = {
        bash = nix_builtins.import_nix "nixpkgs#bash",
      },
    },
  dev.packages.nickel | default = nix_builtins.import_nix "organist#nickel",
  dev.packages.nls | default = nix_builtins.import_nix "organist#nls",
}
