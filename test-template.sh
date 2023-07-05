#!/usr/bin/env bash

set -xeuo pipefail

test_one () {
  target="$1"
  PROJECT_ROOT=$PWD
  WORKDIR=$(mktemp -d)
  function clean() {
    rm -rf "${WORKDIR}"
  }
  trap clean EXIT
  pushd "${WORKDIR}"

  nix flake new --template "path:$PROJECT_ROOT" example --accept-flake-config

  pushd ./example
  sed -i "s/Nickel/$target/" dev-shell.ncl
  # We test against the local version of `nickel-nix`, not the one in main (hence the --override-input).
  nix flake lock --override-input nickel-nix path:$PROJECT_ROOT --accept-flake-config
  nix run .#regenerate-lockfile --accept-flake-config
  nix develop --accept-flake-config --print-build-logs < /dev/null
  popd
  popd
  clean
}

if [[ -n ${1+x} ]]; then
  test_one "$1"
else
  all_targets=$(nickel export <<<'std.record.fields (import "builders.ncl") |> std.string.join " "')
  for target in $all_targets; do
    test_one $target
  done
fi


target=${1:-Nickel}
