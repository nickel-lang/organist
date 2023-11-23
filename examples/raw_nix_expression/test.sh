#!/usr/bin/env bash

set -euo pipefail

python3 <<<'import yaml; print(yaml.dump({"message": "Hello from python in Organist"}))'
