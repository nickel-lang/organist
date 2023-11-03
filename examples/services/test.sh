#!/usr/bin/env bash

set -euo pipefail
set -x

# cat Procfile

nix run .#start-services -- check
nix run .#start-services -- start&
START_SERVICES_PID=$!
trap "kill $START_SERVICES_PID; wait" EXIT

sleep 2
pg_isready -h localhost -p "$POSTGRES_PORT" -t 10
redis-cli -u "$REDIS_URI" ping
