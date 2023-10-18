let nix = import "./nix-interop/nix.ncl" in
{
  File = {
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
      | nix.derivation.NixString,
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
  },
  Files = { _ : File },
  NormaliseTargets = fun label files =>
    files
    |> std.record.map (fun name file_descr => file_descr & { target | default = name }),

  Schema = {
    files
      | Files
      | NormaliseTargets
      | doc m%"
        Set of files that should be generated in the project's directory.
      "%
      = {},
    flake.apps.regenerate-files.program = nix-s%"%{regenerate_files files}/bin/regenerate-files"%,
  },

  regenerate_files | Files -> nix.derivation.Derivation = fun files_to_generate =>
      let regnerate_one | String -> File -> nix.derivation.NixString = fun key file_descr =>
          let file_content = file_descr.content in
          let target = file_descr.target in
          let copy_command =
            match {
              'Symlink => "ln -s",
              'Copy => "cp",
            }
              file_descr.materialisation_method
          in
          let file_in_store =
            nix.builtins.to_file
              (nix.utils.escape_drv_name key)
              file_content
          in
          nix-s%"
            rm -f %{target}
            echo "Regenerating %{target}"
            %{copy_command} %{file_in_store} %{target}
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
        | nix.builders.ShellApplication,
}
