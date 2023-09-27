let organist = import "../lib/nix.ncl" in
let helloScriptFromText =
  {
    name = "hello",
    text = m%"
      #!/bin/sh

      echo "Hello World"
    "%,
  }
    | organist.builders.ShellApplication
in
let helloScriptFromFile =
  {
    name = "hello",
    file = "tests/hello.sh",
  }
    | organist.builders.ShellApplication
in
organist.builders.NixpkgsPkg
& {
  name = "test-writescript",
  version = "0.1",
  env.buildCommand =
    nix-s%"
    [[ $(%{helloScriptFromFile}/bin/hello) == "Hello World" ]]
    [[ $(%{helloScriptFromFile}/bin/hello) == "Hello World" ]]
    echo OK > $out
  "%
      | organist.contracts.NixString,
}
