let organist = import "../lib/nix.ncl" in
let file1 = organist.lib.to_file "file1" "important data" in
let file2 = organist.lib.to_file "file2" nix-s%"see %{file1}"% in
organist.builders.NixpkgsPkg
& {
  name = "test-to_path",
  env.buildCommand = nix-s%"
    [[ $(cat %{file1}) == "important data" ]]
    [[ $(cat %{file2}) == "see /nix/store/ypiiqm7ig0fzqfz3v4j05g54ffk8svg9-file1" ]]
    echo OK > $out
  "%,
}
