let files = import "files.ncl" in
let Attributes = {
  confirm | optional | String | doc m%"Require confirmation prior to executing recipe with a custom prompt"%,
  doc | optional | String | doc m%"Set recipe's documentation comment to `DOC`"%,
  group | optional | String | doc m%"Put recipe in recipe group `NAME`"%,
  linux | optional | Bool | doc m%"Enable recipe on Linux"%,
  macos | optional | Bool | doc m%"Enable recipe on MacOS"%,
  no-cd | optional | Bool | doc m%"Don't change directory before executing recipe"%,
  no-exit-message | optional | Bool | doc m%"Don't print an error message if recipe fails"%,
  no-quiet | optional | Bool | doc m%"Override globally quiet recipes and always echo out the recipe"%,
  positional-arguments | optional | Bool | doc m%"Turn on positional arguments for this recipe"%,
  private | optional | Bool | doc m%"Make the recipe private"%,
  unix | optional | Bool | doc m%"Enable recipe on Unixes. (Includes MacOS)"%,
  windows | optional | Bool | doc m%"Enable recipe on Windows"%,
}
in
let print_attribute = fun name value =>
  if std.is_string value then
    let escape = fun val =>
      val
      |> std.string.characters
      |> std.array.map
        (
          match {
            "\\" => "\\\\",
            "\"" => "\\\"",
            c => c,
          }
        )
      |> std.string.join ""
    in
    m%"[%{name}("%{escape value}")]"%
  else
    "[%{name}]"
in
let print_attributes = fun attrs =>
  attrs
  |> std.record.filter (fun name val => val != false)
  |> std.record.map print_attribute
  |> std.record.values
  |> std.string.join "\n"
in
let Recipe = {
  command
    | doc m%"Commmand to run"%
    | String,
  dependencies
    | doc m%"
      Dependencies of the recipe
    "%
    | { _ : Bool }
    | default
    = {},
  attributes
    | doc m%"
      Extra attributes for the recipe, as defined in https://just.systems/man/en/chapter_34.html
    "%
    | Attributes
    | default
    = {}
}
in
let print_recipe | String -> Recipe -> String
  = fun name recipe =>
    m%"
    %{print_attributes recipe.attributes}
    %{name}: %{std.record.filter (std.function.second) recipe.dependencies |> std.record.fields |> std.string.join " "}
        %{std.string.replace "\n" "\n    " recipe.command}
    "%
  in
{
  Schema =
    files.Schema
    & {
      just
        | doc m%%"
        Integration with the [just](https://just.systems) command runner
      "%%
        = {
          enable
            | doc "Whether to enable the integration"
            | Bool
            | default
            = false,
          recipes
            | doc m%"
              The rules to add in the justfile. See https://just.systems/man/en/chapter_20.html for inspiration.
            "%
            | {
              _ | Recipe
            }
        }
    },
  config | Schema
    = {
      just.recipes = {},
      shells.build.packages.just,
      files =
        if just.enable then
          {
            "justfile".content = m%"
              %{std.record.map print_recipe just.recipes
                |> std.record.values
                |> std.string.join "\n\n"}
            "%,
          }
        else
          {},
    }
}
