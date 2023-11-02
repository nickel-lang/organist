let nix = import "./nix-interop/nix.ncl" in
let ProcfileCommand = nix.derivation.NixString
in
let ProcfileSchema = { _ : ProcfileCommand }
in
let generate_procfile | ProcfileSchema -> nix.derivation.NixString = fun schema =>
    schema
    |> std.record.to_array
    |> std.array.fold_left
      (
        fun acc { field, value } =>
          nix-s%"
            %{acc}
            %{field}: %{value}
          "%
      )
      ""
  in
{
  Schema = {
    procfile
      | doc m%"
        Contents of the [Procfile](https://devcenter.heroku.com/articles/procfile) for deploying on some platforms or local testing.
      "%
      | ProcfileSchema
      | default
      = {},
    files =
      if procfile != {} then
        {
          "Procfile".content = generate_procfile procfile
        }
      else
        {},
    ..
  }
}
