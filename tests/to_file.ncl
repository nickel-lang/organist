let organist = import "../lib/organist.ncl" in
let file1 = organist.nix.builtins.to_file "file1" "important data" in
let file2 = organist.nix.builtins.to_file "file2" nix-s%"see %{file1}"% in
organist.nix.builders.NixpkgsPkg
& {
  name = "test-to_path",
  version = "0.1",
  env.buildCommand = nix-s%"
    [[ $(cat %{file1}) == "important data" ]]
    [[ $(cat %{file2}) == "see /nix/store/wr3qac28s69nkm4x8gg9rrs8518kiwa0-file1" ]]
    echo OK > $out
  "%,
}
