let {GenericBuilder} = import "../builders.ncl" in
{
  name = "hello-world",
  version = "1.0",
  system = {arch = "x86_64", os = "linux"},

  install_phase = m%"
    echo "Hello, world" > $out
  "%m,
} | GenericBuilder
