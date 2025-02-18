#!/bin/bash
set -eu -o pipefail
"$PWD"/.venv/bin/pip install "moto[server] == ${MOTO_VERSION}"
nohup "$PWD"/.venv/bin/moto_server --host 0.0.0.0 --port 4615 &
echo "Pausing for moto to warm up ..." >&2
sleep 2
