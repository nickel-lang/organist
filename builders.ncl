# let some_function = fun {args1, .., argsn} => (ret_value : Foo)
# let x = {args1, .., argsn, ret_value = some_function {args1, .., argns}}
# SomeFuncInterface = {args1, .., argsn}
# SomeFunc = {args1, .., argsn, ret_value}
# Drv == Foo
let {NixStringFragment, ..} = import "nix.ncl" in
{
  nix_string_hack_unsafe = fun fs =>
    {
      type = `nixString, fragments = fs,
    },
  # Nix may require name, version, etc. to have a certain format, but we're not sure. TODO
  # later.
  Name = Str,
  Version = Str,
  #TODO: better contract for strings that can have context
  StringWithCtxt = fun label value =>
    if builtin.is_str value then
      nix_string_hack_unsafe [value] # Array Str
                                     #       ___
    else
      let result = value | Array NixStringFragment in
      nix_string_hack_unsafe result,
  # For now, we use Str, but same thing: should we have enums tags for arch and
  # os instead?
  System = {arch | Str, os | Str},
 
  # TODO: either a Nix derivation (computed) or a Nickel derivation.
  Derivation = Dyn,

  NickelPkg 
    | doc m%"
        The basic, low-level interface for a symbolic derivation to be passed
        to the Nix side in order to be built.
      "%
    = {
      name
        | doc "The name of the package."
        | Name,
      # in Nix, the version isn't actually strictly required by the interface of
      # derivation. But we probably want to impose it if we are to redefine the
      # API on the Nickel side.
      version
        | doc "The version of the package."
        | optional
        | Version,
      dependencies
        | doc "The dependencies of the package."
        | Array Derivation
        | default = [],
      system
        | doc "The system to build the package on."
        | System
        | default = {arch = "x86_64", os = "linux"},
      build_command
        | doc "The build command to execute."
        | {cmd | StringWithCtxt, args | Array StringWithCtxt},
      env
        | doc "Set additional environment variables for the builder."
        | {_: StringWithCtxt},
      # "derivation"
      type | force = `nickelDerivation,
  },

  NickelShell = {
    name | Name,
    packages | Array Derivation
             | default = [],
    type | force = `nickelShell,
    ..
  },
}

#{
#  BinShBuilder = DerivationInterface & {
#    build_script | Str,
#    build_command = [
#      "/bin/sh",
#      ((import "nix_builtins.ncl").write_text "builder" build_script).path,
#    ],
#  },
#
#  GenericCargoBuilder = BinShBuilder & {
#    cargo | Derivation,
#
#    build_script = "%{cargo}/bin/cargo build",
#  },
#
#  Cargo5Builder = GenericCargoBuilder & {
#    build_inputs = { cargo5 },
#    cargo = build_inputs.cargo5,
#  },
#
#  Drv = {out, drv_path}, 
#
#  drv_builder = {
#    name | Str,
#    version | Str,
#    system | Str,
#    build_command | Array Str,
#    derivation | Drv = nix_builtins.derivation name version system build_command,
#  },
#
#  PackageDef = BinShBuilder & {
#    inputs | default = {},
#    build_inputs | default = {},
#    install_phase | Str | default = "",
#    build_phase | Str | default = "",
#    build_script | Str = m%"
#      %{build_phase}
#      %{install_phase}
#    "%m,
#    ..
#  },
#
#  DerivationInterface = {
#    name | Str,
#    version | Str,
#    system | {arch | Str, os | Str} 
#           | default = {arch = "x86_64", os = "linux"},
#    build_command | Array Str,
#    ..
#  },
#
#  # Do we want a syntax like ..DerivationInterface?
#  Derivation = {
#    name | Str,
#    version | Str,
#    system | {..},
#    build_command | Array Str,
#    derivation | {..},
#  },
#
#  Package = PackageDef & {
#   derivation | Drv,
#  },
#
#  Unit = Dyn,
#  Effect = fun contract => Dyn,
#}
