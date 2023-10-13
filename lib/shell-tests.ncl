# By default simply call all package names with `--version` flag
std.record.map
  (
    fun name shells =>
      {
        tests =
          # Use fields => map => merge_all instead of plain std.records.map to set default priority on fields
          shells.dev.packages
          |> std.record.fields
          |> (std.array.map (fun name => { "%{name}" | default = name ++ " --version" }))
          |> std.record.merge_all,
      }
  )
  (import "./organist.ncl").shells
& {
  # Override all cases where `--version` does not work or is not enough
  Go.tests = {
    go = "go version",
    gopls = "gopls version",
  },
  C.tests.clang-tools = "clangd --version",
  Php.tests.php = "php -v",
  Zig.tests.zig = "zig version",
  Javascript.tests = {
    nodejs = "node --version",
    ts-lsp = "typescript-language-server --version",
  },
  Python310.tests.python-lsp = "pylsp --version",
  Erlang.tests = {
    erlang = "erl -version",
    erlang-lsp = "erlang_ls --version",
  },
  HaskellStack.tests = {
    stack' = "",
  },
}
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
