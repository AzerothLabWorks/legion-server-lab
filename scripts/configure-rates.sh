#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/configure-rates.sh PRESET [options]

Configure Legion progression rates without editing worldserver.conf by hand.

Presets:
  blizzlike     1x reputation, 1 profession skill point, 1x XP
  balanced      2x reputation, 2 profession skill points, 1.25x XP (recommended)
  accelerated   3x reputation, 3 profession skill points, 1.5x XP
  custom        Requires --reputation, --profession, and --xp

Options:
  --reputation RATE  Global reputation multiplier (0.1 through 10)
  --profession N     Skill points per successful profession gain (1 through 10)
  --xp RATE          Kill, quest, exploration, and gathering XP multiplier (0.1 through 5)
  --no-restart       Save and apply the config but do not restart worldserver
  --help             Show this help

Examples:
  bash scripts/configure-rates.sh balanced
  bash scripts/configure-rates.sh blizzlike
  bash scripts/configure-rates.sh custom --reputation 4 --profession 3 --xp 1.25

If a character is online, the helper saves the settings but does not interrupt
the session. An administrator can run .reload config in game, or run this helper
again after players log out, to activate the saved rates.
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/.env"
restart_world=1
reputation_override=""
profession_override=""
xp_override=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

[[ "$#" -ge 1 ]] || {
    usage >&2
    exit 1
}

preset="$1"
shift
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --reputation)
            [[ "$#" -ge 2 ]] || { echo "--reputation requires a value" >&2; exit 1; }
            reputation_override="$2"
            shift 2
            ;;
        --profession)
            [[ "$#" -ge 2 ]] || { echo "--profession requires a value" >&2; exit 1; }
            profession_override="$2"
            shift 2
            ;;
        --xp)
            [[ "$#" -ge 2 ]] || { echo "--xp requires a value" >&2; exit 1; }
            xp_override="$2"
            shift 2
            ;;
        --no-restart)
            restart_world=0
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# shellcheck source=scripts/lib/rate-settings.sh
source "$repo_root/scripts/lib/rate-settings.sh"

if [[ "$preset" == "custom" ]]; then
    [[ -n "$reputation_override" && -n "$profession_override" && -n "$xp_override" ]] || {
        echo "The custom preset requires --reputation, --profession, and --xp." >&2
        exit 1
    }
    reputation_rate="$reputation_override"
    profession_rate="$profession_override"
    xp_rate="$xp_override"
else
    defaults="$(legion_rate_preset_values "$preset")" || {
        echo "Unknown preset: $preset" >&2
        echo "Choose blizzlike, balanced, accelerated, or custom." >&2
        exit 1
    }
    IFS=$'\t' read -r reputation_rate profession_rate xp_rate <<<"$defaults"
    if [[ -n "$reputation_override" || -n "$profession_override" || -n "$xp_override" ]]; then
        reputation_rate="${reputation_override:-$reputation_rate}"
        profession_rate="${profession_override:-$profession_rate}"
        xp_rate="${xp_override:-$xp_rate}"
        preset="custom"
    fi
fi

legion_validate_decimal_rate "$reputation_rate" reputation 10
legion_validate_profession_rate "$profession_rate"
legion_validate_decimal_rate "$xp_rate" XP 5

[[ -f "$env_file" ]] || {
    echo "Missing $env_file; run the installer first." >&2
    exit 1
}

temp_env="$(mktemp "$repo_root/.env.rates.XXXXXX")"
temp_world=""
cleanup() {
    rm -f -- "$temp_env"
    [[ -z "$temp_world" ]] || rm -f -- "$temp_world"
}
trap cleanup EXIT

awk \
    -v preset="$preset" \
    -v reputation="$reputation_rate" \
    -v profession="$profession_rate" \
    -v xp="$xp_rate" '
    BEGIN {
        found_preset = found_reputation = found_profession = found_xp = 0
    }
    /^LEGION_RATE_PRESET=/ {
        print "LEGION_RATE_PRESET=\"" preset "\""
        found_preset = 1
        next
    }
    /^LEGION_RATE_REPUTATION=/ {
        print "LEGION_RATE_REPUTATION=\"" reputation "\""
        found_reputation = 1
        next
    }
    /^LEGION_RATE_PROFESSION=/ {
        print "LEGION_RATE_PROFESSION=\"" profession "\""
        found_profession = 1
        next
    }
    /^LEGION_RATE_XP=/ {
        print "LEGION_RATE_XP=\"" xp "\""
        found_xp = 1
        next
    }
    { print }
    END {
        if (!found_preset) print "LEGION_RATE_PRESET=\"" preset "\""
        if (!found_reputation) print "LEGION_RATE_REPUTATION=\"" reputation "\""
        if (!found_profession) print "LEGION_RATE_PROFESSION=\"" profession "\""
        if (!found_xp) print "LEGION_RATE_XP=\"" xp "\""
    }
' "$env_file" > "$temp_env"

chown --reference="$env_file" "$temp_env" 2>/dev/null || true
chmod 600 "$temp_env"
mv "$temp_env" "$env_file"
trap cleanup EXIT

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

world_config="$LEGION_RUNTIME_ROOT/config/worldserver.conf"
if [[ ! -f "$world_config" ]]; then
    echo "Saved rate preset '$preset' in $env_file."
    echo "The settings will be applied when the runtime is prepared."
    exit 0
fi

temp_world="$(mktemp "$LEGION_RUNTIME_ROOT/config/worldserver.conf.rates.XXXXXX")"
awk \
    -v reputation="$reputation_rate" \
    -v profession="$profession_rate" \
    -v xp="$xp_rate" '
    BEGIN {
        xp_kill = xp_quest = xp_explore = xp_gathering = 0
        rep = craft = gather = 0
    }
    /^Rate[.]XP[.]Kill[[:space:]]*=/ { print "Rate.XP.Kill = " xp; xp_kill = 1; next }
    /^Rate[.]XP[.]Quest[[:space:]]*=/ { print "Rate.XP.Quest = " xp; xp_quest = 1; next }
    /^Rate[.]XP[.]Explore[[:space:]]*=/ { print "Rate.XP.Explore = " xp; xp_explore = 1; next }
    /^Rate[.]XP[.]Gathering[[:space:]]*=/ { print "Rate.XP.Gathering = " xp; xp_gathering = 1; next }
    /^Rate[.]Reputation[.]Gain[[:space:]]*=/ { print "Rate.Reputation.Gain = " reputation; rep = 1; next }
    /^SkillGain[.]Crafting[[:space:]]*=/ { print "SkillGain.Crafting = " profession; craft = 1; next }
    /^SkillGain[.]Gathering[[:space:]]*=/ { print "SkillGain.Gathering = " profession; gather = 1; next }
    { print }
    END {
        if (!xp_kill) print "Rate.XP.Kill = " xp
        if (!xp_quest) print "Rate.XP.Quest = " xp
        if (!xp_explore) print "Rate.XP.Explore = " xp
        if (!xp_gathering) print "Rate.XP.Gathering = " xp
        if (!rep) print "Rate.Reputation.Gain = " reputation
        if (!craft) print "SkillGain.Crafting = " profession
        if (!gather) print "SkillGain.Gathering = " profession
    }
' "$world_config" > "$temp_world"

chown --reference="$world_config" "$temp_world" 2>/dev/null || true
chmod --reference="$world_config" "$temp_world" 2>/dev/null || chmod 600 "$temp_world"
mv "$temp_world" "$world_config"
temp_world=""

cat <<EOF
Saved and applied rate preset '$preset':
  Reputation: ${reputation_rate}x
  Profession skill gain: ${profession_rate} point(s) per successful gain
  XP: ${xp_rate}x
EOF

if [[ "$restart_world" -eq 0 ]]; then
    echo "worldserver restart skipped; the new rates activate on its next restart."
    exit 0
fi

cd "$repo_root"
world_container="$(docker compose ps -q worldserver 2>/dev/null || true)"
if [[ -z "$world_container" ]]; then
    echo "worldserver is not running; the new rates activate when it starts."
    exit 0
fi

online_count=""
if online_count="$(docker compose exec -T mysql \
    mysql -N -uroot -p"$LEGION_DB_ROOT_PASSWORD" legion_characters \
    -e 'SELECT COUNT(*) FROM characters WHERE online <> 0;' 2>/dev/null)" && \
    [[ "$online_count" =~ ^[0-9]+$ ]]; then
    if (( online_count > 0 )); then
        echo "$online_count character(s) are online; worldserver was not restarted."
        echo "Run .reload config from an administrator character to activate them now,"
        echo "or run this command again after everyone logs out."
        exit 0
    fi
else
    echo "Could not verify whether players are online; worldserver was not restarted." >&2
    echo "Restart it manually during a safe maintenance window." >&2
    exit 0
fi

docker compose restart worldserver
echo "worldserver restarted; the new rates are active."
