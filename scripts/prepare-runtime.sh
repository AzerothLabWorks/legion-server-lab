#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="${LEGION_SOURCE_ROOT:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
runtime_root="${LEGION_RUNTIME_ROOT:-$HOME/legion-server-runtime}"
install_root="${LEGION_INSTALL_ROOT:-$runtime_root/server}"
build_image="${LEGION_BUILD_IMAGE:-legion-server-build:ubuntu18.04}"
db_password="${LEGION_DB_PASSWORD:?set LEGION_DB_PASSWORD before preparing runtime configuration}"
db_archive="$source_root/sql/base/Legion_Proyect-DB.7z"

if [[ ! -f "$db_archive" ]]; then
    echo "Database archive not found: $db_archive" >&2
    exit 1
fi

if [[ ! -x "$install_root/bin/worldserver" || ! -x "$install_root/bin/bnetserver" ]]; then
    echo "Built servers not found under: $install_root/bin" >&2
    echo "Run scripts/build-core.sh first." >&2
    exit 1
fi

mkdir -p "$runtime_root/config" "$runtime_root/database-init" "$runtime_root/data" "$runtime_root/logs"
rm -f "$runtime_root/database-init"/*.sql

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$db_archive:/input/database.7z:ro" \
    --volume "$runtime_root/database-init:/output" \
    "$build_image" \
    bash -lc '7z e -y /input/database.7z -o/output >/dev/null'

mv "$runtime_root/database-init/legion_auth.sql" "$runtime_root/database-init/10-legion_auth.sql"
mv "$runtime_root/database-init/legion_characters.sql" "$runtime_root/database-init/20-legion_characters.sql"
mv "$runtime_root/database-init/legion_hotfixes.sql" "$runtime_root/database-init/30-legion_hotfixes.sql"
mv "$runtime_root/database-init/legion_world.sql" "$runtime_root/database-init/40-legion_world.sql"

cat > "$runtime_root/database-init/00-create-databases.sql" <<'SQL'
CREATE DATABASE IF NOT EXISTS legion_auth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS legion_characters CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS legion_hotfixes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS legion_world CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON legion_auth.* TO 'legion'@'%';
GRANT ALL PRIVILEGES ON legion_characters.* TO 'legion'@'%';
GRANT ALL PRIVILEGES ON legion_hotfixes.* TO 'legion'@'%';
GRANT ALL PRIVILEGES ON legion_world.* TO 'legion'@'%';
SQL

for database in auth characters hotfixes world; do
    sql_file="$runtime_root/database-init/$(case "$database" in auth) echo 10;; characters) echo 20;; hotfixes) echo 30;; world) echo 40;; esac)-legion_${database}.sql"
    temp_file="${sql_file}.tmp"
    printf 'USE `legion_%s`;\n' "$database" > "$temp_file"
    cat "$sql_file" >> "$temp_file"
    mv "$temp_file" "$sql_file"
done

required_world_update="$source_root/sql/updates/world/2023_04_02_quest_autocomplete.sql"
{
    printf 'USE `legion_world`;\n'
    cat "$required_world_update"
} > "$runtime_root/database-init/50-required-world-schema.sql"

{
    printf 'USE `legion_hotfixes`;\n'
    cat "$source_root/sql/updates/hotfix/0001_fix_garrison_mission_db_structure.sql"
} > "$runtime_root/database-init/60-required-hotfix-schema.sql"

install -m 0644 "$repo_root/database/70-nordrassil-coin-localization.sql" \
    "$runtime_root/database-init/70-nordrassil-coin-localization.sql"

sed \
    -e "s#^LoginDatabaseInfo.*#LoginDatabaseInfo = \"mysql;3306;legion;$db_password;legion_auth\"#" \
    -e 's#^Game.Build.Version.*#Game.Build.Version = 26365#' \
    "$install_root/etc/bnetserver.conf.dist" > "$runtime_root/config/bnetserver.conf"

sed \
    -e "s#^LoginDatabaseInfo.*#LoginDatabaseInfo = \"mysql;3306;legion;$db_password;legion_auth\"#" \
    -e "s#^WorldDatabaseInfo.*#WorldDatabaseInfo = \"mysql;3306;legion;$db_password;legion_world\"#" \
    -e "s#^CharacterDatabaseInfo.*#CharacterDatabaseInfo = \"mysql;3306;legion;$db_password;legion_characters\"#" \
    -e "s#^HotfixDatabaseInfo.*#HotfixDatabaseInfo = \"mysql;3306;legion;$db_password;legion_hotfixes\"#" \
    -e 's#^DataDir.*#DataDir = "/opt/legion/data"#' \
    -e 's#^LogsDir.*#LogsDir = "/opt/legion/logs"#' \
    -e 's#^Game.Build.Version.*#Game.Build.Version = 26365#' \
    -e 's#^AuctionHouseBot.Seller.Enabled.*#AuctionHouseBot.Seller.Enabled = 0#' \
    -e 's#^AuctionHouseBot.Buyer.Enabled.*#AuctionHouseBot.Buyer.Enabled = 0#' \
    -e 's#^CompanionAutoLoot.Enable.*#CompanionAutoLoot.Enable = 1#' \
    -e 's#^CompanionAutoLoot.Radius.*#CompanionAutoLoot.Radius = 40#' \
    -e 's#^CompanionAutoLoot.OutOfCombatOnly.*#CompanionAutoLoot.OutOfCombatOnly = 0#' \
    -e 's#^StartupQoL.Enable.*#StartupQoL.Enable = 1#' \
    "$install_root/etc/worldserver.conf.dist" > "$runtime_root/config/worldserver.conf.tmp"

# The archived upstream template repeats these two update-system keys. Its
# config parser rejects duplicates, so retain only their first occurrence.
awk '
    /^SourceDirectory[[:space:]]*=/ { if (seen_source++) next }
    /^MySQLExecutable[[:space:]]*=/ { if (seen_mysql++) next }
    /^[[:space:]]+PlayedTimeReward\.Money[[:space:]]*$/ { next }
    { print }
' "$runtime_root/config/worldserver.conf.tmp" > "$runtime_root/config/worldserver.conf"
rm "$runtime_root/config/worldserver.conf.tmp"

echo "Prepared configuration and database bootstrap files under $runtime_root"
