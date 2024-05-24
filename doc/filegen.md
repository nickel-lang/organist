# Generating files with Organist

Organist can be used to manage configuration files on the repository through the `files` option.

For instance:

```nickel
let schema = import "devcontainer-schema.ncl" in
{
  files.".containers.json".content = 
    let listen_port : Number = 3000 in
    let config | schema = {
      image = "ghcr.io/nixos/nix:latest",
      forwardPorts = [listen_port],
      containerEnv.MY_APP_LISTEN_PORT = std.to_string listen_port,
    }
    in
    std.serialize 'Toml config,
}
```

(where `devcontainer-schema.ncl` is generated from https://raw.githubusercontent.com/devcontainers/spec/main/schemas/devContainer.base.schema.json using https://github.com/nickel-lang/json-schema-to-nickel).

This has two main advantages:

1. It allows keeping everything under control (compared to a bunch of dotfiles everywhere that are easy to loose track of)
2. It is now possible to benefit from the flexibility and safety of Nickel in these files.
    In the example above, being able to specify a schema for the devcontainer config means that it's possible to get some early check and not have to wait for the CI to fail to detect a typo.

## Usage

The files specified in `files.*` are regenerated automatically when entering
the devshell (unless `filegen_hook` is set to false).

They can also be regenerated manually with:

```bash
nix run .#regenerate-files
```

## Exposed options

### `files`

`{ _ : File }`

Set of files that should be generated in the project's directory.

### `files.*.content`

- `NixString`

The content of the file.

### `files.*.materialisation_method`

- `[| 'Symlink, 'Copy |]`

How the file should be materialized on-disk.

Symlinking makes it easier to track where the files are coming from,
but their target only exists after a first call to Organist, which
might be undesirable.

### `files.*.target`

- `String`

The file to write to.
If unset, defaults to the attribute name of the file.
