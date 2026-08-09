#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="${LEGION_SOURCE_ROOT:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
set -a
source "$repo_root/.env"
set +a

cd "$repo_root"
docker compose exec -T mysql mysql -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_auth \
    -e "UPDATE realmlist SET address='127.0.0.1', localAddress='127.0.0.1', port=8085, gamebuild=26365 WHERE id=1;"

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
