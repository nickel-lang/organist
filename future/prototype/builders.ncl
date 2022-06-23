let nix_builtins = import "nix_builtins.ncl" in

{
  BinShBuilder = Derivation & drv_builder & {
    build_script | Str,
    build_command = [
      "/bin/sh",
      (nix_builtins.write_text "builder" build_script)
    ],
  },

  drv_builder = {
    name | Str,
    version | Str,
    system | Str,
    build_command | Str,
    derivation | Drv = nix_builtins.derivation name version system build_command,
  },

  PackageDef = BinShBuilder & {
    inputs | default = [],
    build_inputs | default = [],
    install_phase | Str | default = "",
    build_phase | Str | default = "",
    build_script | Str = m%"
      %{build_phase}
      %{install_phase}
    "%m,
    ..
  },

  DerivationInterface = {
    name | Str,
    version | Str,
    system | {..},
    ..
  },

  # Do we want a syntax like ..DerivationInterface?
  Derivation = {
    name | Str,
    version | Str,
    system | {..},
    build_command | Str,
    derivation | {..},
  },

  Package = PackageDef & {
   derivation | Drv,
  },

  Unit = fun label => function.id,

  Effect = fun x => x,
}
