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
    | nix.derivation.NullOr nix.derivation.NixString
    | default
    = null,
  file
    | doc "File from which to read the body of the script"
    | nix.derivation.NullOr nix.derivation.NixString
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
    = 'Copy,
  ..
}
in
let Files = { _ : File }
in
let NormaliseTargets = fun label files =>
  files
  |> std.record.map (fun name file_descr => file_descr & { target | default = name })
in
let regenerate_files | Files -> nix.derivation.Derivation = fun files_to_generate =>
    let regnerate_one | String -> File -> nix.derivation.NixString = fun key file_descr =>
        let target = file_descr.target in
        let copy_command =
          match {
            'Symlink => "ln -s",
            'Copy => "cp",
          }
            file_descr.materialisation_method
        in
        nix-s%"
            rm -f %{target}
            echo "Regenerating %{target}"
            target_dir=$(dirname %{target})
            test "${target_dir}" != "." && mkdir -p "${target_dir}"
            # XXX: If `source.file` is set explicitely to a relative path
            # and `materialisation_method` is `'Symlink`, this will link to the
            # original file, not one in the store. Not sure that's what we want.
            %{copy_command} %{file_descr.file} %{target}
          "%
      in
    {
      name = "regenerate-files",
      content.text =
        files_to_generate
        |> std.record.to_array
        |> std.array.map (fun { field, value } => regnerate_one field value)
        |> std.array.fold_left
          (
            fun acc elt =>
              nix-s%"
                  %{acc}
                  %{elt}
                "%
          )
          "",
    }
      | nix.builders.ShellApplication
  in
{
  Schema = {
    files
      | Files
      | NormaliseTargets
      | doc m%"
        Set of files that should be generated in the project's directory.
      "%
      = {},
    filegen_hook.enable
      | Bool
      | doc m%"
        Enable a hook that will automatically regenerate the files managed by
        Nickel when entering the shell.
      "%
      | default
      = true,
    flake.apps, # Forward declaration. Not great but would need some refactor to fix
    shells,
  },
  config | Schema = {
      files,
      filegen_hook,
      shells,
      flake.apps.regenerate-files.program = nix-s%"%{regenerate_files files}/bin/regenerate-files"%,

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
