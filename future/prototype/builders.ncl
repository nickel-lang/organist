let nix_builtins = import "nix_builtins.ncl" in
let Drv = Dyn in

# let some_function = fun {args1, .., argsn} => (ret_value : Foo)
# let x = {args1, .., argsn, ret_value = some_function {args1, .., argns}}
# SomeFuncInterface = {args1, .., argsn}
# SomeFunc = {args1, .., argsn, ret_value}
# Drv == Foo
{
  BinShBuilder =
    DerivationInterface
    & {
      build_script | String,
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
    name | String,
    version | String,
    system | String,
    build_command | Array String,
    derivation | Drv = nix_builtins.derivation name version system build_command,
  },

  PackageDef =
    BinShBuilder
    & {
      inputs | default = {},
      build_inputs | default = {},
      install_phase | String | default = "",
      build_phase | String | default = "",
      build_script | String = m%"
      %{build_phase}
      %{install_phase}
    "%,
      ..
    },

  DerivationInterface = {
    name | String,
    version | String,
    system
      | { arch | String, os | String }
      | default
      = { arch = "x86_64", os = "linux" },
    build_command | Array String,
    ..
  },

  # Do we want a syntax like ..DerivationInterface?
  Derivation = {
    name | String,
    version | String,
    system | { .. },
    build_command | Array String,
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
