let builders = import "../builders.ncl" in
let derivation = import "../derivation.ncl" in
let packages = import "../packages.ncl" in
let Bash = import "./bash.ncl" in

let
# Haskell Language Server (HLS) uses a different Ormolu version than the default one, and it's difficult to change it for now.
# See https://github.com/haskell/haskell-language-server/issues/411
# So we do the opposite: retrieve the Ormolu package transitively pulled by HLS.
# Note that Ormolu is a level 2 transitive dependency of HLS: `haskell-language-server` -> `hls-ormolu-plugin` -> `ormolu`
ormoluFromHls = fun hls =>
  derivation.CallNix
  & {
    function = m%"
      hls:
        let
          # Build the attrset of dependency packages of `p`
          getDependencies = p: builtins.listToAttrs
            (map (dependency: { name = dependency.pname; value = dependency; }) p.passthru.getBuildInputs.haskellBuildInputs);

          hlsDependencies = getDependencies hls;
          hlsOrmoluPluginDependencies = getDependencies hlsDependencies.hls-ormolu-plugin;
        in
        hlsOrmoluPluginDependencies.ormolu.bin
    "%,
    args = hls,
  }
in

Bash
& {
  build.ghcVersion
    | doc m%"
            The GHC version used in the build.
            Must be kept in sync with the one expected by Stack.
          "%
    | String
    | default
    = "default",
  build.packages =
    let stack-wrapped =
      {
        name = "stack-wrapped",
        version = "1.0",
        build_command = {
          cmd = nix-s%"%{packages.import_nix "nixpkgs#bash"}/bin/bash"%,
          args = [
            "-c",
            nix-s%"
                  source .attrs.sh
                  export PATH='%{packages.import_nix "nixpkgs#coreutils"}/bin'":$PATH"
                  mkdir -p ${outputs[out]}/bin
                  echo "$0" > ${outputs[out]}/bin/stack
                  chmod a+x ${outputs[out]}/bin/*
                "%,
            nix-s%"
                  #!%{packages.import_nix "nixpkgs#bash"}/bin/bash
                  %{packages.import_nix "nixpkgs#stack"}/bin/stack \
                    --nix \
                    --no-nix-pure \
                    --nix-path="nixpkgs=%{packages.import_nix "nixpkgs#path"}" \
                    "$@"
                "%,
          ],
        },
      }
        | builders.NickelPkg
    in
    {
      stack,
      nix,
      git,
      stack' = stack-wrapped,
    },
  dev.ghcVersion | force = build.ghcVersion,
  dev.packages =
    let ghcPackageSet =
      if dev.ghcVersion == "default" then
        "haskellPackages"
      else
        "haskell.packages.ghc%{dev.ghcVersion}"
    in
    {
      ormolu = ormoluFromHls haskell-language-server,
      haskell-language-server = packages.import_nix "nixpkgs#%{ghcPackageSet}.haskell-language-server",
    },
}
