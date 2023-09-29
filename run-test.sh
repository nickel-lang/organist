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

  STORED_LOCKFILE_CONTENTS="$(cat nickel.lock.ncl)"
  TEST_SCRIPT="$(nickel export --format raw <<<'(import "'"$PROJECT_ROOT"'/lib/shell-tests.ncl").'"$target"'.script')"

  echo "Running with incorrect nickel.lock.ncl" 1>&2
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  echo "Running without nickel.lock.ncl" 1>&2
  rm nickel.lock.ncl
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  echo "Run with proper nickel.lock.ncl" 1>&2
  nix run .\#regenerate-lockfile
  PROPER_LOCKFILE_CONTENTS="$(cat nickel.lock.ncl)"
  nix develop --accept-flake-config --print-build-logs --command bash <<<"$TEST_SCRIPT"

  echo "Testing without flakes" 1>&2
  # restore lockfile
  cat > nickel.lock.ncl <<<"$STORED_LOCKFILE_CONTENTS"
  # pretend it's not flake anymore
  rm flake.*
  cat > shell.nix <<EOF
let
  pkgs = import <nixpkgs> {};
  organistSrc = builtins.path { path = "$PROJECT_ROOT"; name = "source"; };
  organist = pkgs.callPackage "\${organistSrc}/lib/lib.nix" {inherit organistSrc;};
in
  (organist.importNcl {baseDir = ./.;}).shells.default
EOF

  echo "Running with incorrect nickel.lock.ncl" 1>&2
  nix develop --impure -f shell.nix -I nixpkgs="$NIXPKGS_PATH" --command bash <<<"$TEST_SCRIPT"

  echo "Running without nickel.lock.ncl" 1>&2
  rm nickel.lock.ncl
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
    test_one_template "$1"
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
