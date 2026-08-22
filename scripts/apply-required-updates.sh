#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="${LEGION_SOURCE_ROOT:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
set -a
source "$repo_root/.env"
set +a

realm_address="${LEGION_REALM_ADDRESS:-127.0.0.1}"
if [[ ! "$realm_address" =~ ^[A-Za-z0-9][A-Za-z0-9.-]{0,252}[A-Za-z0-9]$ ]] && \
    [[ ! "$realm_address" =~ ^[A-Za-z0-9]$ ]]; then
    echo "Invalid LEGION_REALM_ADDRESS: $realm_address" >&2
    echo "Use an IPv4 address or DNS hostname containing only letters, digits, dots, and hyphens." >&2
    exit 1
fi

cd "$repo_root"
docker compose exec -T mysql mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_auth \
    -e "UPDATE realmlist SET address='$realm_address', localAddress='$realm_address', port=8085, gamebuild=26365, Region=1, Battlegroup=1 WHERE id=1;"

echo "Realm 1 now advertises: $realm_address:8085"

docker compose exec -T mysql mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_world \
    -e "INSERT INTO autobroadcast (id, text) VALUES
        (1, 'Welcome to the Nordrassil local Legion test server.'),
        (2, 'This is a private development realm. Gameplay issues may be caused by incomplete server scripts.'),
        (3, 'Use the GM account only for local testing and troubleshooting.'),
        (4, 'Remember to report reproducible server issues with the character, zone, quest, and steps involved.')
        ON DUPLICATE KEY UPDATE text=VALUES(text);"

for schema_update in \
    "legion_auth:auth/2023_03_04_version.sql" \
    "legion_characters:characters/2023_03_04_version.sql"; do
    schema="${schema_update%%:*}"
    update_file="${schema_update#*:}"
    version_ready="$(docker compose exec -T mysql mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
        -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$schema' AND TABLE_NAME='version';")"
    if [[ "$version_ready" == "0" ]]; then
        docker compose exec -T mysql \
            mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" "$schema" \
            < "$source_root/sql/updates/$update_file"
    fi
done

world_script_columns_ready="$(docker compose exec -T mysql mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='legion_world' AND TABLE_NAME IN ('creature','gameobject') AND COLUMN_NAME='ScriptName';")"
if [[ "$world_script_columns_ready" != "2" ]]; then
    docker compose exec -T mysql \
        mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_world \
        < "$source_root/sql/updates/world/2022_08_04_00_world.sql"
fi

quest_script_column_ready="$(docker compose exec -T mysql mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='legion_world' AND TABLE_NAME='quest_template_addon' AND COLUMN_NAME='ScriptName';")"
if [[ "$quest_script_column_ready" == "0" ]]; then
    docker compose exec -T mysql \
        mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_world \
        < "$source_root/sql/updates/world/2022_08_04_01_world.sql"
fi

world_ready="$(docker compose exec -T mysql mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='legion_world' AND TABLE_NAME='quest_objectives' AND COLUMN_NAME='Bugged';")"
if [[ "$world_ready" == "0" ]]; then
    docker compose exec -T mysql \
        mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_world \
        < "$source_root/sql/updates/world/2023_04_02_quest_autocomplete.sql"
fi

hotfix_ready="$(docker compose exec -T mysql mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='legion_hotfixes' AND TABLE_NAME='garr_mission' AND COLUMN_NAME='RelationshipData';")"
if [[ "$hotfix_ready" == "0" ]]; then
    docker compose exec -T mysql \
        mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_hotfixes \
        < "$source_root/sql/updates/hotfix/0001_fix_garrison_mission_db_structure.sql"
fi

docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    < "$repo_root/database/70-nordrassil-coin-localization.sql"

docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    < "$repo_root/database/80-deduplicate-static-creature-spawns.sql"

docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    < "$repo_root/database/81-deduplicate-nearby-singleton-npcs.sql"

docker compose exec -T mysql \
    mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" \
    < "$repo_root/database/82-deduplicate-nearby-cross-generation-creatures.sql"
