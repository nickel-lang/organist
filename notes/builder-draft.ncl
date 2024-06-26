# Draft notepad took during Nixel sessions, brainstorming about the interface
# and the interface of Nickel devshell builders.
{
  BinShBuilder =
    DerivationInterface
    & {
      build_script | Str,
      build_command = [
        "/bin/sh",
        ((import "nix_builtins.ncl").write_text "builder" build_script).path,
      ],
    },

  GenericCargoBuilder =
    BinShBuilder
    & {
      cargo | Derivation,

      build_script = "%{cargo}/bin/cargo build",
    },

  Cargo5Builder =
    GenericCargoBuilder
    & {
      build_inputs = { cargo5 },
      cargo = build_inputs.cargo5,
    },

  Drv = { out, drv_path },

  drv_builder = {
    name | Str,
    version | Str,
    system | Str,
    build_command | Array Str,
    derivation | Drv = nix_builtins.derivation name version system build_command,
  },

  PackageDef =
    BinShBuilder
    & {
      inputs | default = {},
      build_inputs | default = {},
      install_phase | Str | default = "",
      build_phase | Str | default = "",
      build_script | Str
        =
          m%"
            %{build_phase}
            %{install_phase}
          "%
            m,
      ..
    },

  DerivationInterface = {
    name | Str,
    version | Str,
    system
      | { arch | Str, os | Str }
      | default
      = { arch = "x86_64", os = "linux" },
    build_command | Array Str,
    ..
  },

  # Do we want a syntax like ..DerivationInterface?
  Derivation = {
    name | Str,
    version | Str,
    system | { .. },
    build_command | Array Str,
    derivation | { .. },
  },

  Package =
    PackageDef
    & {
      derivation | Drv,
    },

  Unit = Dyn,
  Effect = fun contract => Dyn,
}
