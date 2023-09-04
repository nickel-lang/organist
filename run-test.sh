#!/usr/bin/env bash

set -euo pipefail

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
  NIXPKGS_PATH="$(nix flake metadata --json --inputs-from "path:$PROJECT_ROOT" nixpkgs | nix eval --impure --raw --expr '(builtins.fromJSON (builtins.readFile "/dev/stdin")).path')"
  # We test against the local version of `organist` not the one in main (hence the --override-input).
  nix flake lock \
    --override-input organist "path:$PROJECT_ROOT" \
    --override-input nixpkgs "path:$NIXPKGS_PATH" \
    --accept-flake-config
  nix run .#regenerate-lockfile --accept-flake-config
}

# Note: running in a subshell (hence the parens and not braces around the function body) so that the trap-based cleanup happens whenever we exit
test_one_template () (
  target="$1"
  set -x
  pushd_temp

  nix flake new --template "path:$PROJECT_ROOT" example --accept-flake-config

  pushd ./example
  sed -i "s/shells\.Bash/shells.$target/" project.ncl
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
    all_targets=$(nickel export --format raw <<<'std.record.fields ((import "lib/nix.ncl").shells) |> std.string.join "\n"')
    echo "$all_targets" | parallel --tag "$0" template
  fi
}

test_example () (
  set -x
  examplePath=$(realpath "$1")
  pushd_temp
  cp -r "$examplePath" ./example
  pushd ./example
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
