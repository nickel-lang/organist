#!/usr/bin/env bash

set -euo pipefail
set -x

cat Procfile

honcho -f Procfile check
honcho -f Procfile start&
HONCHO_PID=$!
trap "kill $HONCHO_PID; wait" EXIT

sleep 2
pg_isready -h localhost -p "$POSTGRES_PORT" -t 10
redis-cli -u "$REDIS_URI" ping
