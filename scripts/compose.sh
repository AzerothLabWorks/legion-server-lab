#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$repo_root/.env" ]]; then
    echo "Missing $repo_root/.env; run scripts/init-local-env.sh first." >&2
    exit 1
fi

set -a
source "$repo_root/.env"
set +a

if [[ ! -d "$LEGION_DATA_ROOT/dbc" ]]; then
    echo "Legion DBC directory not found under LEGION_DATA_ROOT: $LEGION_DATA_ROOT" >&2
    exit 1
fi

cd "$repo_root"
exec docker compose "$@"
