let nix = import "./nix-interop/nix.ncl" in
let ExtensionFromMarketplace = {
  publisher | String,
  name | String,
  version | String,
  sha256 | String
} in
let VSCodeSchema = {
  extensions
  | doc "Extensions to install locally in the workspace"
  | { _ : ExtensionFromMarketplace }
  | default = {}
} in
let BuiltExtensionDetails = {
  name | String,
  path | nix.derivation.NixString,
} in
let buildExtension : String -> ExtensionFromMarketplace -> BuiltExtensionDetails = fun extName efm =>
      { name = extName,
      path = nix.derivation.CallNix & { function = m%"
          {vscode-utils, extension-ref}:
            vscode-utils.buildVscodeMarketplaceExtension
            { mktplcRef = extension-ref; }
        "%,
        args = {
            vscode-utils = nix.import_nix "nixpkgs#vscode-utils",
            extension-ref = {
              publisher = efm.publisher,
              name = efm.name,
              version = efm.version,
              sha256 = efm.sha256
            },
          }
      }} | BuiltExtensionDetails in
let regenerate-vscode | { _ : ExtensionFromMarketplace} -> nix.derivation.Derivation = fun exts =>
  { name = "regenerate-vscode",
    content.text = exts
      |> std.record.to_array
      |> std.array.map (fun {field = extName, value = ext} => buildExtension extName ext)
      |> std.array.fold_left
        ( fun acc elt =>
          nix-s%"
            %{acc}
            ln -sf %{elt.path}/share/vscode/extensions/* ".vscode/extensions/" 
          "%)
          "",
  } | nix.builders.ShellApplication
in {
  Schema = {
    vscode | doc m%"
      VSCode configuration
      "% | VSCodeSchema | default
        = {},
    flake.apps.regenerate-vscode.program = nix-s%"%{regenerate-vscode vscode.extensions}/bin/regenerate-vscode"%,
  },
}
