let { NickelDerivation, Derivation, NixString, NixEnvironmentVariable, NullOr, .. } = import "derivation.ncl" in

let lib = import "builtins.ncl" in

let concat_strings_sep = fun sep values =>
  if std.array.length values == 0 then
    ""
  else
    std.array.reduce_left (fun acc value => nix-s%"%{acc}%{sep}%{value}"%) values
in

let MutExclusiveWith = fun other name other_name label value =>
  if value == null && other == null then
    std.fail_with "You must specify either %{name} or %{other_name} field"
  else if value != null && other != null then
    std.fail_with "You can set only one of %{name} or %{other_name} fields"
  else
    value
in
{
  NickelPkg
  # we should only need two '%%', but a current Nickel bug (#XXX) bug makes the example being
  # recognized as actual interpolation. For the time being, we thus use a
  # three '%' delimiter.
    | doc m%%%"
      The most basic builder. Simply alias to `NickelDerivation`.

      Example:

      Here is a simple example of a function producing a Nickel derivation
      using the `NickelPkg` builder.

      ```nickel
      output = fun { inputs, nix, .. } =>
      {
        name = "hello",
        version = "0.1",
        build_command = {
          cmd = nix-s%"%{inputs.bash}/bin/bash"%,
          args = [ "-c",
            nix-s%"
              %{inputs.gcc}/bin/gcc %{nix.lib.import_file "hello.c"} -o hello
              %{inputs.coreutils}/bin/mkdir -p $out/bin
              %{inputs.coreutils}/bin/cp hello $out/bin/hello
             "%
          ]
        },
      } | nix.builders.NickelPkg
      ```
      "%%%
    = NickelDerivation,

  NixpkgsPkg
    | doc m%"
      Makes a derivation that runs all the build phases from nixpkgs' stdenv as the `build_command`.
      Can be controlled with environment variables in the same way as `stdenv.mkDerivation`.
    "%
    =
      {
        name,
        version,
        build_command = {
          cmd = nix-s%"%{lib.import_nix "nixpkgs#bash"}/bin/bash"%,
          args = ["-c", "set -euo pipefail; source \"${NIX_ATTRS_SH_FILE:-.attrs.sh}\"; source $stdenv/setup; genericBuild"],
        },
        structured_env = {},
        env
          | doc "Environment variables that will be set in the derivation"
          | { _ : NixEnvironmentVariable }
          = {
            stdenv | default = lib.import_nix "nixpkgs#stdenv",
          },
        nix_drv =
          let env' = env in
          env' & structured_env & { env = env' },
      }
        | NickelPkg,

  Shell
    | doc m%"
      A derivation that is to be used as a shell, e.g. with `nix develop`.
      Analogous to `mkShell`.
    "%
    =
      NixpkgsPkg
      & {
        hooks | doc "Bash scripts to run when entering the shell" = {},

        name | default = "shell",
        version | default = "dev",
        packages | doc "Packages to be added to the shell, setting PATH, LD_LIBRARY_PATH and other variables as needed" = {},

        env.buildCommand = nix-s%"
          echo "This derivation is not supposed to be built" 1>&2 1>/dev/null
          exit 1
        "%,
        env.shellHook = concat_strings_sep "\n" (std.record.values hooks),
        structured_env.nativeBuildInputs = packages,
      }
        | NickelPkg,

  ShellApplication
    | doc m%"
      A derivation that writes contents of `content.file` to `bin/$name` in the output and makes it executable.
      `content.file` defaults to a file with text from `content.text`.
      The script is prepended with:
      - #! line that points to `shell_binary` (defaults to `nixpkgs#runtimeShell`)
      - sane shell configuration
      - if `runtime_inputs` is specified, `/bin` directories of those inputs are added to PATH
      The result is verified with `bash -n` and `shellcheck`.
    "%
    =
      NixpkgsPkg
      & {
        name,
        version | default = "0.0.0",
        content
          | doc m%"
            The body of the script. Can be either passed directly as a string,
            or read from a file
          "%,
        content.text
          | doc "A string representing the body of the script"
          | NullOr NixString
          | default
          = null,
        content.file
          | doc "File from which to read the body of the script"
          | NullOr NixString
          | default
          =
            if content.text == null then
              null
            else
              lib.to_file name content.text,
        runtime_inputs
          | doc m%"
            Packages which will be added to the `PATH` of the script when
            it runs.

            # Example

            ```nickel
            {
              jq = import_nix "nixpkgs#jq",
              nickel = import_nix "nixpkgs#awk",
            }
            ```
          "%
          | { _ : Derivation }
          = {},
        shell_binary
          | doc m%"
            The binary that will be run to execute the script.
            Needs to be bash-compatible.
          "%
          | NixString
          | default
          = lib.import_nix "nixpkgs#runtimeShell",

        env.buildInputs.coreutils = lib.import_nix "nixpkgs#coreutils",
        env.buildCommand = nix-s%"
          mkdir -p "${outputs[out]}/bin"
          target="${outputs[out]}/bin/${name}"
          (cat <<<"$scriptHeader"; cat "%{content.file}") > "$target"
          chmod +x "$target"
          %{lib.import_nix "nixpkgs#stdenv.shellDryRun"} "$target"
          "%{lib.import_nix "nixpkgs#shellcheck"}/bin/shellcheck" "$target"
        "%,
        env.scriptHeader =
          let path_line =
            if std.record.is_empty runtime_inputs then
              ""
            else
              let paths =
                runtime_inputs
                |> std.record.values
                |> std.array.map (fun s => nix-s%"%{s}/bin"%)
                |> concat_strings_sep ":"
              in
              nix-s%"export PATH="%{paths}:$PATH""%
          in
          nix-s%"
            #!%{shell_binary}
            set -o errexit
            set -o nounset
            set -o pipefail
            %{path_line}
          "%,
      }
        | NickelPkg,
}
