let derivation = import "../derivation.ncl" in
let nix_builtins = import "../builtins.ncl" in
let Targets = import "./rust-targets.ncl" in
let Bash = import "./bash.ncl" in
let RustShell = {
  channel
    | [| 'stable, 'beta, 'nightly |]
    | doc "The rust channel"
    | default
    = 'stable,
  extraTargets | doc "Extra targets to install, for cross-compilation"
    = Targets,

  components | doc "Rust components to install"
    = {
      rustc | default = true,
      cargo | default = true,
      rust-std | default = true,
      rust-docs | default = false,
      rustfmt | default = false,
      rust-analyzer | default = false,
      clippy | default = false,
      miri | default = false,
      rust-src | default = false,
    },

  packages.rustc =
    # Maybe we should default to "complete" instead of "latest"? Tier 2 targets only
    # have "latest", though...
    let toolchain = if channel == 'nightly then "latest" else std.string.from_enum channel in
    let targetNames = std.record.filter (fun n v => v) extraTargets |> std.record.fields in
    let targets = std.array.map (fun x => nix_builtins.import_nix "fenix#targets.%{x}.%{toolchain}.rust-std") targetNames in
    let componentNames =
      std.record.filter (fun name value => value) components
      |> std.record.fields
    in
    derivation.CallNix
    & {
      function = "{ withComponents, components }: withComponents components",
      args = {
        withComponents = nix_builtins.import_nix "fenix#combine",
        components =
          componentNames
          |> std.array.map (fun x => nix_builtins.import_nix "fenix#%{toolchain}.%{x}")
          |> std.array.concat targets,
      },
    },
}
in
Bash
& {
  build = RustShell,
  dev =
    RustShell
    & {
      # This should probably have the default priority, but it gets merged with
      # build.components and if it's default then they clash.
      components = {
        rust-docs = true,
        rustfmt = true,
        clippy = true,
        rust-analyzer = true,
      }
    },
}
