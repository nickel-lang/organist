let nix = import "./nix-interop/nix.ncl" in
let ProcfileCommand = nix.derivation.NixString
in
let ProcfileSchema = { _ : ProcfileCommand }
in
let generate_procfile | ProcfileSchema -> nix.derivation.NixString
  = fun schema =>
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
    services
      | doc m%%%"
        Services required for development.

        These can be started with `nix run .#start-services start`.

        ## Example

        ```nickel
        {
          redis = nix-s%"%{organist.import_nix "nixpkgs#redis"}/bin/redis-server --port %{std.to_string redis_listen_port}"%,
          minio = nix-s%"%{organist.import_nix "nixpkgs#minio"}/bin/minio server ./.minio-data"%,
        }
        ```
      "%%%
      | { _ : nix.derivation.NixString }
      | default
      = {},
    flake.apps,
  },
  config | Schema
    = {
      services,
      flake.apps =
        if services != {} then
          let procfile = nix.builtins.to_file "Procfile" (generate_procfile services) in
          {
            start-services.type = "app",
            start-services.program | nix.derivation.NixString
              =
                let run =
                  nix.builders.ShellApplication
                  & {
                    name = "start-services",
                    content.text = nix-s%"exec %{nix.import_nix "nixpkgs#honcho"}/bin/honcho -f %{procfile} "$@""%
                  }
                in nix-s%"%{run}/bin/start-services"%
          }
        else
          {},
    },
}
