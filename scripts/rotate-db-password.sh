#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/.env"
set -a
source "$env_file"
set +a

new_password="$(openssl rand -hex 24)"
cd "$repo_root"
docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "ALTER USER 'legion'@'%' IDENTIFIED BY '$new_password'; FLUSH PRIVILEGES;"

awk -v password="$new_password" '
    /^LEGION_DB_PASSWORD=/ { print "LEGION_DB_PASSWORD=\"" password "\""; next }
    { print }
' "$env_file" > "$env_file.tmp"
chmod 600 "$env_file.tmp"
mv "$env_file.tmp" "$env_file"

set -a
source "$env_file"
set +a
bash "$repo_root/scripts/prepare-runtime.sh"

docker compose run --rm --no-deps --entrypoint sh worldserver \
    -c 'find /opt/legion/logs -maxdepth 1 -type f -exec truncate -s 0 {} +'
echo "Rotated the local database application password and regenerated configuration."
