# By default simply call all package names with `--version` flag
let test_command_for = fun package =>
  package
  |> std.string.to_enum
  |> match {
    'nls => "nls --help",
    'go => "go version",
    'gopls => "gopls version",
    'clang-tools => "clangd --version",
    'php => "php -v",
    'zig => "zig version",
    'nodejs => "node --version",
    'ts-lsp => "typescript-language-server --version",
    'python-lsp => "pylsp --version",
    'erlang => "erl -version",
    'erlang-lsp => "erlang_ls --version",
    'stack' => "",
    _ => "%{package} --version",
  }
in
std.record.map
  (
    fun name shells =>
      {
        tests =
          # Use fields => map => merge_all instead of plain std.records.map to set default priority on fields
          shells.dev.packages
          |> std.record.fields
          |> (std.array.map (fun name => { "%{name}" = test_command_for name }))
          |> std.record.merge_all,
      }
  )
  (import "./organist.ncl").shells
  | {
    _ : {
      script | String | default =
          # Enable all usual bash error handling options
          # Also redirect stdout to stderr to avoid it interleaving when going through `parallel`
          let lines = std.string.join "\n" (std.record.values tests) in
          m%"
            set -euxo pipefail
            exec 1>&2
            %{lines}
          "%,
      tests | { _ : String },
    }
  }
