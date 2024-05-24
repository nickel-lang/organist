#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage:

$0 template [--full] <shellName> -- test instantiating the template using the given shell
$0 template -- test instantiating all the templates
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
  # Use a temporary file to pass data to `nix eval` because of https://github.com/NixOS/nix/issues/9330
  nix flake metadata --json --inputs-from "path:$PROJECT_ROOT" nixpkgs > "${WORKDIR}/meta.json"
  # Note that we cannot pass neither path nor JSON itself using --arg* because of https://github.com/NixOS/nix/issues/2678
  NIXPKGS_PATH="$(nix eval --impure --raw --expr '(builtins.fromJSON (builtins.readFile "'"${WORKDIR}/meta.json"'")).path')"
  # We test against the local version of `organist` not the one in main (hence the --override-input).
  nix flake update \
    --override-input organist "path:$PROJECT_ROOT" \
    --override-input nixpkgs "path:$NIXPKGS_PATH" \
    --accept-flake-config
}

# Note: running in a subshell (hence the parens and not braces around the function body) so that the trap-based cleanup happens whenever we exit
test_one_template () (
  local isFull=false
  if [[ ${1:-""} == "--full" ]]; then
    isFull=true
    shift
  fi
  target="$1"
  set -x
  pushd_temp

  nix flake new --template "path:$PROJECT_ROOT" example --accept-flake-config

  pushd ./example
  sed -i "s/shells\.Bash/shells.$target/" project.ncl
  prepare_shell

  STORED_LOCKFILE_CONTENTS="$(cat nickel.lock.ncl)"
  TEST_SCRIPT="$(nickel export --format raw <<<'(import "'"$PROJECT_ROOT"'/lib/shell-tests.ncl").'"$target"'.script')"

  echo "Running with incorrect nickel.lock.ncl" 1>&2
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  if [[ $isFull == false ]]; then
    return
  fi

  echo "Running without nickel.lock.ncl" 1>&2
  rm -f nickel.lock.ncl
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  echo "Run with proper nickel.lock.ncl" 1>&2
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  echo "Testing without flakes" 1>&2
  # restore lockfile
  rm -f nickel.lock.ncl
  cat > nickel.lock.ncl <<<"$STORED_LOCKFILE_CONTENTS"
  # pretend it's not flake anymore
  rm flake.*
  cat > shell.nix <<EOF
let
  organist = import "$PROJECT_ROOT";
in
  (organist.flake.outputsFromNickel ./. {
    inherit organist;
    nixpkgs = import <nixpkgs> {};
  } {}).devShells.\${builtins.currentSystem}.default
EOF

  echo "Running with incorrect nickel.lock.ncl" 1>&2
  nix develop --impure -f shell.nix -I nixpkgs="$NIXPKGS_PATH" --command bash <<<"$TEST_SCRIPT"

  echo "Running without nickel.lock.ncl" 1>&2
  rm -f nickel.lock.ncl
  nix develop --impure -f shell.nix -I nixpkgs="$NIXPKGS_PATH" --command bash <<<"$TEST_SCRIPT"

  echo "Run with proper nickel.lock.ncl" 1>&2
  cat > nickel.lock.ncl <<<"$PROPER_LOCKFILE_CONTENTS"
  nix develop --impure -f shell.nix -I nixpkgs="$NIXPKGS_PATH" --command bash <<<"$TEST_SCRIPT"

  popd
  popd
  clean
)

test_template () {
  if [[ -n ${1+x} ]]; then
    test_one_template "$@"
  else
    all_targets=$(nickel export --format raw <<<'std.record.fields ((import "lib/organist.ncl").shells) |> std.string.join "\n"')
    # --line-buffer outputs one line at a time, as opposed to dumping all output at once when job finishes
    # --keep-order makes sure that the order of the output corresponds to the job order, keeping output for each job together
    # --tag prepends each line with the name of the job
    echo "$all_targets" | parallel --line-buffer --keep-order --tag "$0" template
  fi
}

test_example () (
  set -x
  examplePath=$(realpath "$1")
  pushd_temp
  cp -r "$examplePath" ./example
  pushd ./example
  prepare_shell
  nix develop --print-build-logs --command bash test.sh
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
