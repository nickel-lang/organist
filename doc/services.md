# Managing services with Organist

Organist allows you to declare a set of services that need to be running when developing your project, through the `services` option, exposed by `organist.services`.

These can then be started with `nix run .#start-services start`.

For instance, if the `project.ncl` contains:

```nickel
let redis_listen_port = 64442 in
{
  services.redis = nix-s%"%{organist.import_nix "nixpkgs#redis"}/bin/redis-server --port %{std.to_string redis_listen_port}"%,
}
  | (
    organist.OrganistExpression
    & organist.services.Schema
  )
```

then running `nix run .#start-services start` will run a local `redis` instance listening on port 64442.

A more complete example can be found [here](../examples/services/project.ncl).

## Exposed options

### `services`

 - `{ _ : NixString }`

Services required for development.
