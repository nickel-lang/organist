#!/usr/bin/env bash

set -euo pipefail

gcc -lhello main.c -o hello
./hello
