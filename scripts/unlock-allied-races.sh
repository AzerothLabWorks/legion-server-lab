#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/unlock-allied-races.sh BATTLE_NET_EMAIL [WOW_ACCOUNT_INDEX]

Grant the four Legion allied-race unlock achievements to one local game account.
WOW_ACCOUNT_INDEX defaults to 1, which normally corresponds to WoW1.

Example:
  bash scripts/unlock-allied-races.sh player@example.com 1
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/.env"
email="${1:-}"
account_index="${2:-1}"

if [[ "$email" == "--help" || "$email" == "-h" ]]; then
    usage
    exit 0
fi

if [[ -z "$email" ]]; then
    usage >&2
    exit 2
fi

if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$ ]]; then
    echo "Invalid Battle.net email address: $email" >&2
    exit 2
fi

if [[ ! "$account_index" =~ ^[1-9][0-9]*$ ]] || (( account_index > 255 )); then
    echo "WOW_ACCOUNT_INDEX must be an integer from 1 through 255." >&2
    exit 2
fi

if [[ ! -f "$env_file" ]]; then
    echo "Missing $env_file; run the installer first." >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

: "${LEGION_DB_ROOT_PASSWORD:?LEGION_DB_ROOT_PASSWORD is missing from .env}"

cd "$repo_root"
if ! docker compose ps --status running mysql --format '{{.Service}}' 2>/dev/null | grep -qx mysql; then
    echo "The Legion MySQL service is not running. Start it with:" >&2
    echo "  bash scripts/compose.sh up -d mysql" >&2
    exit 1
fi

mysql_query() {
    docker compose exec -T mysql mysql \
        --batch --skip-column-names --raw \
        -uroot -p"$LEGION_DB_ROOT_PASSWORD" "$@" </dev/null
}

account_row="$(mysql_query legion_auth -e "
SELECT a.id, a.username, a.expansion
FROM account AS a
INNER JOIN battlenet_accounts AS b ON b.id = a.battlenet_account
WHERE UPPER(b.email) = UPPER('$email')
  AND a.battlenet_index = $account_index
LIMIT 1;
")"

if [[ -z "$account_row" ]]; then
    echo "No linked WoW$account_index game account was found for $email." >&2
    echo "Create the account first or supply its correct WoW account index." >&2
    exit 1
fi

IFS=$'\t' read -r account_id account_name account_expansion <<<"$account_row"
if (( account_expansion < 6 )); then
    echo "Game account $account_name has expansion level $account_expansion; Legion requires 6." >&2
    exit 1
fi

first_guid="$(mysql_query legion_characters -e "
SELECT COALESCE(MIN(guid), 0)
FROM characters
WHERE account = $account_id;
")"
if [[ "$first_guid" == "0" ]]; then
    echo "Game account $account_name has no character to associate with account achievements." >&2
    echo "Create one normal character, then run this command again." >&2
    exit 1
fi

requirement_count="$(mysql_query legion_world -e "
SELECT COUNT(*)
FROM race_unlock_requirement
WHERE raceID IN (27, 28, 29, 30)
  AND achievementId IN (12242, 12243, 12244, 12245)
  AND expansion <= $account_expansion;
")"
if [[ "$requirement_count" != "4" ]]; then
    echo "Expected four build-26365 allied-race requirements, found $requirement_count." >&2
    echo "The world database does not match the supported Legion baseline; no changes were made." >&2
    exit 1
fi

mysql_query legion_characters -e "
INSERT INTO account_achievement (account, first_guid, achievement, date)
SELECT $account_id, $first_guid, requirement.achievementId, UNIX_TIMESTAMP()
FROM legion_world.race_unlock_requirement AS requirement
WHERE requirement.raceID IN (27, 28, 29, 30)
  AND requirement.achievementId IN (12242, 12243, 12244, 12245)
  AND requirement.expansion <= $account_expansion
ON DUPLICATE KEY UPDATE first_guid = VALUES(first_guid);
"

granted_count="$(mysql_query legion_characters -e "
SELECT COUNT(*)
FROM account_achievement
WHERE account = $account_id
  AND achievement IN (12242, 12243, 12244, 12245);
")"
if [[ "$granted_count" != "4" ]]; then
    echo "Allied-race achievement verification failed: expected 4, found $granted_count." >&2
    exit 1
fi

cat <<EOF
All four Legion allied races are unlocked for $email / $account_name:
  Void Elf
  Lightforged Draenei
  Nightborne
  Highmountain Tauren

Fully disconnect this client session and reconnect so the login server reloads
the account achievement cache. Normal Legion race/class restrictions remain.
EOF
