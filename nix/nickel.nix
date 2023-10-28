{
  lib,
  rustPlatform,
  nix-update-script,
  python3,
  src,
}:
rustPlatform.buildRustPackage rec {
  pname = "nickel";
  version = "pre-${src.lastModifiedDate or ""}";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = [python3];

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://nickel-lang.org/";
    description = "Better configuration for less";
    longDescription = ''
      Nickel is the cheap configuration language.

      Its purpose is to automate the generation of static configuration files -
      think JSON, YAML, XML, or your favorite data representation language -
      that are then fed to another system. It is designed to have a simple,
      well-understood core: it is in essence JSON with functions.
    '';
    changelog = "https://github.com/tweag/nickel/blob/${version}/RELEASES.md";
    license = licenses.mit;
    maintainers = with maintainers; [AndersonTorres felschr];
  };
}
