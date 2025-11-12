#!/bin/bash
PORT=${FB_PORT:-8080}
ADDRESS=${FB_ADDRESS:-0.0.0.0}

# Use localhost for healthcheck when binding to 0.0.0.0
if [ "${ADDRESS}" = "0.0.0.0" ]; then
    ADDRESS="localhost"
fi

curl -f -s "http://${ADDRESS}:${PORT}/health" > /dev/null || exit 1
