#!/bin/bash
set -eu -o pipefail

echo "[entrypoint.sh]: Running fixuid"
fixuid -q

echo "[entrypoint.sh]: Running make ${*}"
make "$@"
