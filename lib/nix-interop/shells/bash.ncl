let builders = import "../builders.ncl" in
let nix_packages = import "../packages.ncl" in
{
  build =
    builders.Shell
    & {
      packages = {
        bash = nix_packages.import_nix "nixpkgs#bash",
      },
    },
  dev.packages.nickel | priority -100 = nix_packages.import_nix "organist#nickel",
  dev.packages.nls | priority -100 = nix_packages.import_nix "organist#nls",
}
