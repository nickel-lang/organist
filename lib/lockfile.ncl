let filegen = import "files.ncl" in
let nix = import "nix-interop/nix.ncl" in
{
  Schema =
    {
      files."nickel.lock.ncl".file = nix.import_nix "%%organist_internal#nickelLock",
    } | filegen.Schema,
}
