#!/usr/bin/env bash

cat <<EOF > .editorconfig.expected
root = true

[*]
indent_size = 2
indent_style = space
insert_final_newline = true

[*.py]
indent_size = 4
indent_style = space

[Makefile]
indent_style = tab
EOF

diff .editorconfig.expected .editorconfig
