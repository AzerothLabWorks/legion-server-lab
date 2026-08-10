#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/.env"

if [[ -e "$env_file" ]]; then
    echo "Refusing to overwrite existing $env_file" >&2
    exit 1
fi

runtime_root="${LEGION_RUNTIME_ROOT:-$HOME/legion-server-runtime}"
data_root="${LEGION_DATA_ROOT:-$runtime_root/data}"
db_password="$(openssl rand -hex 24)"
db_root_password="$(openssl rand -hex 24)"

umask 077
cat > "$env_file" <<EOF
LEGION_RUNTIME_ROOT="$runtime_root"
LEGION_DATA_ROOT="$data_root"
LEGION_DB_PORT=3310
LEGION_DB_PASSWORD="$db_password"
LEGION_DB_ROOT_PASSWORD="$db_root_password"
EOF

echo "Created local-only environment file: $env_file"
