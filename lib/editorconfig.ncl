let files = import "./files.ncl" in
let IndentSize = fun label value =>
  if value == 'tab then
    value
  else
    std.contract.apply Number label value
in
let ConfigEntry = {
  indent_style | optional | [| 'tab, 'space |],
  indent_size | optional | IndentSize,
  tab_width | optional | Number,
  insert_final_newline | optional | Bool,
  end_of_line | optional | [| 'lf, 'cr, 'crlf |],
  trim_trailing_whitespace | optional | Bool,
  insert_final_newline | optional | Bool,
}
in
let Config = { _ : ConfigEntry } in
let showConfigEntry | String -> ConfigEntry -> String = fun section_name entry =>
    let content =
      entry
      |> std.record.map (fun key value => "%{key} = %{std.to_string value}")
      |> std.record.values
      |> std.string.join "\n"
    in
    m%"
  [%{section_name}]
  %{content}
  "%
  in
let generate
  | Bool -> {
    _ : ConfigEntry
  } -> String
  = fun is_root cfg =>
    m%"
    root = %{std.to_string is_root}

    %{std.record.map showConfigEntry cfg |> std.record.values |> std.string.join "\n\n"}

    "%
  in
let EditorConfigSchema = {
  is_root
    | doc "Whether to stop searching for other editorconfig files above"
    | Bool
    | default
    = true,
  sections
    | doc m%"
        Sections of the editor configuration.
        Keys are patterns defining the files that will be considered, and values are some specific settings for these files.

        ## Example

        ```nickel
        {
          "*" = {
            indent_style = 'space,
            indent_size = 2,
          },

          "Makefile".indent_size = 'tab,
        }
        ```
      "%
    | Config
    | default
    = {},
}
in
files
& {
  Schema = {
    editorconfig
      | doc m%"
        Editor configuration (from https://editorconfig.org/)
      "%
      | EditorConfigSchema
      | default
      = {},
  },
  config | Schema = {
      editorconfig,
      files =
        if editorconfig.sections != {} then
          {
            ".editorconfig" = {
              content = generate editorconfig.is_root editorconfig.sections,
            }
          }
        else
          {},
    },
}
