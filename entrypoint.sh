#!/bin/bash
set -eu -o pipefail

echo "[entrypoint.sh]: Running make ${*}"
make "$@"
