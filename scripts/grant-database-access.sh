#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
source "$repo_root/.env"
set +a

cd "$repo_root"
docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "GRANT ALL PRIVILEGES ON legion_auth.* TO 'legion'@'%';
        GRANT ALL PRIVILEGES ON legion_characters.* TO 'legion'@'%';
        GRANT ALL PRIVILEGES ON legion_hotfixes.* TO 'legion'@'%';
        GRANT ALL PRIVILEGES ON legion_world.* TO 'legion'@'%';
        FLUSH PRIVILEGES;"
