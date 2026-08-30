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
realm_address="${LEGION_REALM_ADDRESS:-127.0.0.1}"
rest_bind_address="${LEGION_REST_BIND_ADDRESS:-127.0.0.1}"
timezone="${LEGION_TIMEZONE:-America/Los_Angeles}"

# shellcheck source=scripts/lib/rate-settings.sh
source "$repo_root/scripts/lib/rate-settings.sh"
legion_resolve_rate_settings

umask 077
cat > "$env_file" <<EOF
LEGION_RUNTIME_ROOT="$runtime_root"
LEGION_DATA_ROOT="$data_root"
LEGION_DB_PORT=3310
LEGION_DB_PASSWORD="$db_password"
LEGION_DB_ROOT_PASSWORD="$db_root_password"
LEGION_REALM_ADDRESS="$realm_address"
LEGION_REST_BIND_ADDRESS="$rest_bind_address"
LEGION_TIMEZONE="$timezone"
LEGION_RATE_PRESET="$LEGION_RATE_PRESET"
LEGION_RATE_REPUTATION="$LEGION_RATE_REPUTATION"
LEGION_RATE_PROFESSION="$LEGION_RATE_PROFESSION"
LEGION_RATE_XP="$LEGION_RATE_XP"
EOF

echo "Created local-only environment file: $env_file"
