{
  Schema = {
    direnv = {
      enable
        | doc m%"
          Whether to enable the [direnv](https://github.com/direnv/direnv) integration.
        "%
        | Bool
        | default
        = true,
    },
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
