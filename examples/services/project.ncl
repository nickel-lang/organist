let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

let postgres_listen_port = 64441 in
let redis_listen_port = 64442 in

{
  shells = organist.shells.Bash,

  shells.build = {
    packages = {},
  },

  shells.dev = {
    packages = {
      postgresql = organist.import_nix "nixpkgs#postgresql",
      redis = organist.import_nix "nixpkgs#redis",
      honcho = organist.import_nix "nixpkgs#honcho",
    },
    env.POSTGRES_PORT = "%{std.to_string postgres_listen_port}",
    env.REDIS_URI = "redis://localhost:%{std.to_string redis_listen_port}",
  },

  services = {
    postgres =
      let start_script =
        {
          name = "start-postgres",
          runtime_inputs.postgres = organist.import_nix "nixpkgs#postgresql",
          content.text = nix-s%"
          mkdir -p ./.postgres-data
          initdb ./.postgres-data
          postgres -D ./.postgres-data -k "$PWD/.postgres-data" -p %{std.to_string postgres_listen_port}

        "%
        } | organist.nix.builders.ShellApplication
      in
      nix-s%"%{start_script}/bin/start-postgres"%,
    redis = nix-s%"%{organist.import_nix "nixpkgs#redis"}/bin/redis-server --port %{std.to_string redis_listen_port}"%,
  },
}
  | (
    organist.OrganistExpression
    & organist.tools.editorconfig.Schema
    & organist.services.Schema
  )
