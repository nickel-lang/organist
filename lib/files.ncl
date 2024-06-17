let nix = import "./nix-interop/nix.ncl" in
let File = {
  target
    | doc m%"
        The file to write to.
        If null, defaults to the attribute name of the file.
      "%
    | String
    | optional,
  content
    | doc m%"
        The content of the file.
      "%
    | nix.derivation.NullOr nix.nix_string.NixString
    | default
    = null,
  file
    | doc "File from which to read the body of the script"
    | nix.derivation.NullOr nix.nix_string.NixString
    | default
    =
      if content == null then
        null
      else
        nix.builtins.to_file "generated-content" content,
  materialisation_method
    : [| 'Symlink, 'Copy |]
    | doc m%"
        How the file should be materialized on-disk.

        Symlinking makes it easier to track where the files are coming from,
        but their target only exists after a first call to Organist, which
        might be undesirable.
      "%
    | default
    = 'Copy
}
in
let Files = { _ : File }
in
let NormaliseTargets = fun label files =>
  files
  |> std.record.map (fun name file_descr => file_descr & { target | default = name })
in
let regenerate_files | Files -> nix.derivation.Derivation
  = fun files_to_generate =>
    let regenerate_function | String
      = m%"
        regenerate_function () {
          COPY_COMMAND="$1"
          SOURCE="$2"
          TARGET="$3"
          if [[ ! -f "$TARGET" ]] || [[ $(cat "$TARGET") != $(cat "$SOURCE") ]]; then
            rm -f "$TARGET"
            echo "Regenerating $TARGET"
            target_dir=$(dirname "$TARGET")
            test "${target_dir}" != "." && mkdir -p "${target_dir}"
            # XXX: If `source.file` is set explicitely to a relative path
            # and `materialisation_method` is `'Symlink`, this will link to the
            # original file, not one in the store. Not sure that's what we want.
            $COPY_COMMAND "$SOURCE" "$TARGET"
          fi
        }
      "%
      in
    let regnerate_one | String -> File -> nix.nix_string.NixString
      = fun key file_descr =>
        let copy_command =
          match {
            'Symlink => "ln -s",
            'Copy => "cp",
          }
            file_descr.materialisation_method
        in
        nix-s%"regenerate_function "%{copy_command}" "%{file_descr.file}" "%{file_descr.target}""%
      in
    let regenerate_files = nix-s%"
      %{regenerate_function}
      %{
        files_to_generate
        |> std.record.map regnerate_one
        |> std.record.values
        |> nix.nix_string.join "\n"
      }
    "%
    in
    {
      name = "regenerate-files",
      content.text = regenerate_files,
    }
      | nix.builders.ShellApplication
  in
{
  Schema =
    {
      files
        | Files
        | NormaliseTargets
        | doc m%%"
        Set of files that should be generated in the project's directory.

        # Examples

        ```nickel
        {
          ".gitignore".content = m%"
              /result
            "%,
        }
        ```

        ```nickel
        {
          ".containers.json".content =
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
      "%%
        = {},
      filegen_hook
        | { enable | Bool }
        | doc m%"
        A hook that will automatically regenerate the files managed by Nickel
        when entering the shell.
      "%
        | default
        = { enable = true },
    }
    & (import "flake.ncl").Schema,
  config | Schema
    = {
      files,
      filegen_hook,
      shells,
      apps.regenerate-files.program = nix-s%"%{regenerate_files files}/bin/regenerate-files"%,

      shells.build.hooks =
        if filegen_hook.enable then
          {
            filegen_hook = nix-s%"
              %{regenerate_files files}/bin/regenerate-files
            "%
          }
        else
          {},
    },
}
