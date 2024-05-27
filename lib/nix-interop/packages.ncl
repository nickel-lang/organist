let derivations = import "derivation.ncl" in
let utils = import "utils.ncl" in
{
  import_nix
    | doc m%%"
      Import a Nix value from one of the flake inputs.
      The value should be passed in a flakeref-like format
      `input_name#attribute_path`.

      # Example

      ```nickel
      cmd = nix-s%"%{import_nix "nixpkgs#hello"}/bin/hello > $out"%
      ```
    "%%
    | derivations.NixInputSugar -> derivations.NixInput
    = fun x => x,

  NixpkgsDerivations = DerivationsFrom "nixpkgs",

  DerivationsFrom = fun input_name label value =>
    std.contract.apply
      (
        utils.WithDefaultValues
          (fun _name => import_nix "%{input_name}#%{_name}")
      )
      label
      value
    |> std.contract.apply { _ : derivations.Derivation } label,
}
