let organist = import "../lib/nix.ncl" in
let helloScriptFromText =
  {
    name = "hello",
    content.text = m%"
      #!/bin/sh

      echo "Hello World"
    "%,
  }
    | organist.builders.ShellApplication
in
let helloScriptFromFile =
  {
    name = "hello",
    content.file = organist.lib.import_file "tests/hello.sh",
  }
    | organist.builders.ShellApplication
in
{
  name = "test-shellapplication",
  env.buildCommand = nix-s%"
    [[ $(%{helloScriptFromText}/bin/hello) == "Hello World" ]]
    [[ $(%{helloScriptFromFile}/bin/hello) == "Hello World" ]]
    echo OK > $out
  "%,
}
