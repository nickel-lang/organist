{
  name = "hello-world",
  version = "1.0",
  system = {arch = "x86_64", os = "linux"},

  install_phase = m%"
    mkdir $out
    echo "Hello, world" > $out/out
  "%m,
}
