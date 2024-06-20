let nix = import "../nix-interop/nix.ncl" in
<<<<<<< HEAD
let OrganistShells = {
  dev
    | doc m%"
||||||| parent of 9e44ee3 (Document the flake fields)
{
  Schema = {
    shells = {
      dev
        | doc m%"
=======
{
  Schema = {
    shells
      | doc m%%"
        Definition of the shell environments for developing or building the project.

        ## Examples

        ```nickel
        # Set a base shell of a Rust project
        organist.shells.Rust
        & {
          # Add a custom dev-only dependency
          dev.packages.prettier = organist.import_nix "nixpkgs#nodePackages.prettier",
        }
        ```

        ```nickel
        # Shell for a mixed OCaml and Rust project
        organist.shells.Rust
        & organist.shells.OCaml
        ```
      "%%
      = {
        dev
          | doc m%"
>>>>>>> 9e44ee3 (Document the flake fields)
      Development shell.

      Contains everything needed to build and work on the project.

      Can be entered with `nix develop .#dev`.
      "%
<<<<<<< HEAD
    | nix.derivation.NickelDerivation,
  build
    | doc m%"
||||||| parent of 9e44ee3 (Document the flake fields)
        | nix.derivation.NickelDerivation,
      build
        | doc m%"
=======
          | nix.derivation.NickelDerivation,
        build
          | doc m%"
>>>>>>> 9e44ee3 (Document the flake fields)
      Build shell.

      Only contains the required dependencies to build the project.

      Can be entered with `nix develop .#build`.
      "%
    | nix.derivation.NickelDerivation,
  "default"
    | doc m%"
      Default shell.

      This is the shell that gets entered by `nix develop` without any argument.

      Defaults to the `dev` shell.
      "%
    | nix.derivation.NickelDerivation,
}
in
{
  Schema = {
    shells
      | doc m%"
        Definition of the shell environments for developing or building the project.

        ## Examples

        ```nickel
        # Set a base shell of a Rust project
        organist.shells.Rust
        & {
          # Add a custom dev-only dependency
          dev.packages.prettier = organist.import_nix "nixpkgs#nodePackages.prettier",
        }
        ```

        ```nickel
        # Shell for a mixed OCaml and Rust project
        organist.shells.Rust
        & organist.shells.OCaml
      "%
      | OrganistShells,
    flake.devShells | { _ | nix.derivation.Derivation },
  },
  config | Schema
    = {
      shells.dev = shells.build,
      shells."default" = shells.dev,
      flake.devShells = shells,
    },
}
