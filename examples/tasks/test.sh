#!/usr/bin/env bash

set -euo pipefail
set -x

# cat Procfile

nix develop --command task --list-all
test_output=$(nix develop --command task test)

echo "$test_output" | grep Foo
echo "$test_output" | grep ran_the_tests
echo "$test_output" | grep ran_the_build
