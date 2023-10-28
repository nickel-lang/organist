let organist = import "../lib/organist.ncl" in
let helloScriptFromText =
  {
    name = "hello",
    content.text = m%"
      #!/bin/sh

      echo "Hello World"
    "%,
  }
    | organist.nix.builders.ShellApplication
in
let helloScriptFromFile =
  {
    name = "hello",
    content.file = organist.nix.builtins.import_file "tests/hello.sh",
  }
    | organist.nix.builders.ShellApplication
in
{
  name = "test-shellapplication",
  version = "0.1",
  env.buildCommand = nix-s%"
    [[ $(%{helloScriptFromText}/bin/hello) == "Hello World" ]]
    [[ $(%{helloScriptFromFile}/bin/hello) == "Hello World" ]]
    echo OK > $out
  "%,
}
