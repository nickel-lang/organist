let organist = import "../lib/nix.ncl" in
let paths = {
  "bin/hello" = organist.lib.import_file "tests/hello.sh",
  "README.md" =
    organist.builders.TextFile
    & {
      name = "README",
      content = "Hello package",
    },
}
in
let file_tree =
  organist.builders.FileTree
  & {
    name = "foobar",
    input_paths = paths,
  }
in
organist.builders.NixpkgsPkg
& {
  name = "test-filetree",
  version = "0.1",
  env.buildCommand =
    nix-s%"
    [[ $(realpath '%{file_tree}/bin/hello') == $(realpath '%{paths."bin/hello"}') ]]
    [[ $(realpath '%{file_tree}/README.md') == $(realpath '%{paths."README.md"}') ]]
    echo "OK" > $out
  "%
      | organist.contracts.NixString,
}
