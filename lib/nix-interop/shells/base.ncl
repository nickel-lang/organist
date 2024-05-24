let builders = import "../builders.ncl" in
let derivation = import "../derivation.ncl" in

let Hook = {
  name
    | doc m%"
        The name of the hook.
        If null, defaults to the attribute name.
      "%
    | String
    | optional,
  enabled
    | doc m%"
      Whether to run the hook
    "%
    | Bool
    | default
    = true,
  verbose
    | doc m%"
      Whether to announce when the hook runs
    "%
    | Bool
    | default
    = true,
  content
    | doc m%"
        The bash snippet to run
      "%
    | derivation.NixString,
}
in
let concat_strings_sep = fun sep values =>
  if std.array.length values == 0 then
    ""
  else
    std.array.reduce_left (fun acc value => nix-s%"%{acc}%{sep}%{value}"%) values
in

let hook_to_string | Hook -> derivation.NixString = fun hook =>
    if hook.enabled then
      let header =
        if hook.verbose then
          nix-s%"
            echo -e '\033[34;1m==> Running hook %{hook.name}\033[0m'
          "%
        else
          nix-s%""%
      in

      nix-s%"
        %{header}
        %{hook.content}
      "%
    else
      nix-s%""%
  in
let NormaliseNames = fun label items =>
  items
  |> std.record.map (fun item_name item => item & { name | default = item_name })
in

builders.NixpkgsPkg
& {
  hooks
    | doc "Bash scripts to run when entering the shell"
    | { _ : Hook }
    | NormaliseNames
    = {},

  name | default = "shell",
  version | default = "dev",
  packages | doc "Packages to be added to the shell, setting PATH, LD_LIBRARY_PATH and other variables as needed" = {},

  env.buildCommand = nix-s%"
          echo "This derivation is not supposed to be built" 1>&2 1>/dev/null
          exit 1
        "%,
  env.shellHook = concat_strings_sep "\n" (std.record.values hooks |> std.array.map hook_to_string),
  structured_env.nativeBuildInputs = packages,
}
  | builders.NickelPkg
