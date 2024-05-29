let builders = import "../builders.ncl" in
let base = import "./base.ncl" in
let nix_builtins = import "../builtins.ncl" in
{
  build =
    base
    & {
      packages = {
        bash = nix_builtins.import_nix "nixpkgs#bash",
      },
    },
  dev.packages.nickel | default = nix_builtins.import_nix "organist#nickel",
  dev.packages.nls | default = nix_builtins.import_nix "organist#nls",
}
