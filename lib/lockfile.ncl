let filegen = import "files.ncl" in
let nix = import "nix-interop/nix.ncl" in
{
  Schema = filegen.Schema,
  config | Schema = {
      files."nickel.lock.ncl".file = nix.import_nix "%%organist_internal#nickelLock",
    }
}
