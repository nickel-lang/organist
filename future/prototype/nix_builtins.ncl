{
  derivation | Str -> Str -> {..} -> Str -> {..} =
    fun name_ version_ system_ build_command_ => {
      name = name_,
      version = version_,
      system = system_,
      build_command = build_command_,
      path = "dummy"
    },
  # we should return a derivation, but let's avoid circular imports for now, and
  # restructure contracts/functions later.
  write_text | Str -> Str -> {..} = fun name_ text => {
    name = name_,
    version = "1.0",
    system = {arch = "x86_64", os = "linux"},
    # what build command?
    build_command = "",
    path = "dummy",
  },
}
