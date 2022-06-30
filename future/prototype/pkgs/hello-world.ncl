let {BinShBuilder, ..} = import "../builders.ncl" in
{
  name = "hello-world",
  version = "1.0",

  build_script = m%"
    echo "Hello, world" > $out
  "%m,
} | BinShBuilder
