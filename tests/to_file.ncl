let organist = import "../lib/organist.ncl" in
let file1 = organist.nix.builtins.to_file "file1" "important data" in
let file2 = organist.nix.builtins.to_file "file2" nix-s%"see %{file1}"% in
organist.nix.builders.NixpkgsPkg
& {
  name = "test-to_path",
  version = "0.1",
  env.buildCommand = nix-s%"
    [[ $(cat %{file1}) == "important data" ]]
    # Note that this line changes every time we update nixpkgs.
    # Keep it pointing to x86_64-linux version to keep CI happy.
    [[ $(cat %{file2}) == "see /nix/store/bzggifmjzdsyqffyvyn516p8rxhh609x-file1" ]]
    echo OK > $out
  "%,
}
