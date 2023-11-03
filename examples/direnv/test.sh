#!/usr/bin/env bash

set -euo pipefail

echo "export FOO=from-direnv" >> .envrc.private

direnv allow
[[ $(direnv exec . sh -c 'echo $DIRENV_FILE') == "$PWD/.envrc" ]]
[[ $(direnv exec . sh -c 'echo $FOO') == "from-direnv" ]]
