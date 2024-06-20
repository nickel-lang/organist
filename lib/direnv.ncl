let files = import "files.ncl" in
{
  Schema =
    files.Schema
    & {
      direnv
        | doc m%"
        [direnv](https://github.com/direnv/direnv) integration.
      "%
        = {
          enable
            | doc "Whether to enable the integration"
            | Bool
            | default
            = false,
        },
    },
  config | Schema
    = {
      direnv,
      files =
        if direnv.enable then
          {
            ".envrc".content = m%"
            if ! has nix_direnv_version || ! nix_direnv_version 2.4.0; then
              source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.4.0/direnvrc" "sha256-XQzUAvL6pysIJnRJyR7uVpmUSZfc7LSgWQwq/4mBr1U="
            fi
            watch_file project.ncl nickel.lock.ncl
            source_env_if_exists ".envrc.private"
            use flake
          "%,
          }
        else
          {},
    },
}
