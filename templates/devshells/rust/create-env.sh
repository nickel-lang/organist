#!/usr/bin/env bash

for devenv in $(awk '/= BashShell/ { print $1 }' ./nixel/builders.ncl)
do
  ENV_NAME="$(echo $devenv | tr [A-Z] [a-z] | sed 's/shell$//')"
  DEST="../$ENV_NAME"
  if ! [[ ./ -ef "$DEST" ]];
  then
    echo $ENV_NAME

    rm -fr "$DEST"
    mkdir -p "$DEST"
    cp -r nixel flake.* "$DEST"

    cat <<EOF > "${DEST}/dev-shell.ncl"
let builders = import "nixel/builders.ncl" in

{
  output = {
    name = "nickel-shell",
  }
} & builders.$devenv
EOF
  fi
done
