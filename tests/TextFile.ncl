let organist = import "../lib/nix.ncl" in
let
  someText = organist.builders.TextFile & {
    name = "foo",
    content = "Heyio"
  }
in
organist.builders.NixpkgsPkg
& {
  name = "test-textfile",
  version = "0.1",
  env.buildCommand =
    nix-s%"
    [[ $(cat %{someText}) == "Heyio" ]]
    echo OK > $out
  "%
      | organist.contracts.NixString,
}
    