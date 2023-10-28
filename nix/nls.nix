{
  rustPlatform,
  nickel,
  python3,
}:
rustPlatform.buildRustPackage {
  pname = "nls";

  inherit (nickel) src version;

  cargoLock = {
    lockFile = "${nickel.src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = [python3];

  cargoBuildFlags = ["-p nickel-lang-lsp"];

  meta = {
    inherit (nickel.meta) homepage changelog license maintainers;
    description = "A language server for the Nickel programming language";
    longDescription = ''
      The Nickel Language Server (NLS) is a language server for the Nickel
      programming language. NLS offers error messages, type hints, and
      auto-completion right in your favorite LSP-enabled editor.
    '';
  };
}
