#!/usr/bin/env bash

set -xeuo pipefail

usage() {
  cat <<EOF
Usage:

$0 template <shellName> -- test instantiating the template using the given shell
$0 example <examplePath> -- Try running the example at <examplePath>
EOF
  exit 1
}

pushd_temp () {
  WORKDIR=$(mktemp -d)
  function clean() {
    rm -rf "${WORKDIR}"
  }
  trap clean EXIT
  pushd "${WORKDIR}"
}

prepare_shell() {
  # We test against the local version of `nickel-nix`, not the one in main (hence the --override-input).
  nix flake lock --override-input nickel-nix path:$PROJECT_ROOT --accept-flake-config
  nix run .#regenerate-lockfile --accept-flake-config
}

# Note: running in a subshell (hence the parens and not braces around the function body) so that the trap-based cleanup happens whenever we exit
test_one_template () (
  target="$1"
  pushd_temp

  nix flake new --template "path:$PROJECT_ROOT" example --accept-flake-config

  pushd ./example
  sed -i "s/BashShell/$target/" dev-shell.ncl
  prepare_shell
  nix develop --accept-flake-config --print-build-logs < /dev/null
  popd
  popd
  clean
)

test_template () {
  if [[ -n ${1+x} ]]; then
    test_one_template "$1"
  else
    all_targets=$(nickel export --format raw <<<'std.record.fields (import "builders.ncl") |> std.string.join " "')
    for target in $all_targets; do
      if [[ "$target" == NickelPkg ]] || [[ "$target" == "NixpkgsPkg" ]]; then
        continue
      fi
      test_one_template $target
    done
  fi
}

test_example () (
  examplePath=$(realpath "$1")
  pushd_temp
  cp -r "$examplePath" .
  pushd *
  prepare_shell
  nix build --print-build-logs
  popd
  popd
)

PROJECT_ROOT=$PWD

if [[ -z ${1+x} ]]; then
  usage
elif [[ $1 == "template" ]]; then
  shift
  test_template "$@"
elif [[ $1 == "example" ]]; then
  shift
  test_example "$@"
else
  usage
fi
