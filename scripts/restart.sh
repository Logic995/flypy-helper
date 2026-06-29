#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

pids="$(pgrep -x 'FlypyHelper' || true)"
if [[ -n "$pids" ]]; then
  echo "$pids" | xargs kill
  sleep 0.5
fi

swift run
