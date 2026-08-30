#!/usr/bin/env bash

# Shared progression-rate presets and validation. This file is sourced by the
# installer, runtime generator, and the operator-facing configuration helper.

legion_rate_preset_values() {
    case "$1" in
        blizzlike)
            printf '1\t1\t1\n'
            ;;
        balanced)
            printf '2\t2\t1.25\n'
            ;;
        accelerated)
            printf '3\t3\t1.5\n'
            ;;
        *)
            return 1
            ;;
    esac
}

legion_validate_decimal_rate() {
    local value="$1"
    local label="$2"
    local maximum="$3"

    if [[ ! "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
        ! awk -v value="$value" -v maximum="$maximum" \
            'BEGIN { exit !(value >= 0.1 && value <= maximum) }'; then
        printf 'Invalid %s rate: %s (expected 0.1 through %s)\n' \
            "$label" "$value" "$maximum" >&2
        return 1
    fi
}

legion_validate_profession_rate() {
    local value="$1"

    if [[ ! "$value" =~ ^[1-9][0-9]*$ ]] || (( value > 10 )); then
        printf 'Invalid profession rate: %s (expected a whole number from 1 through 10)\n' \
            "$value" >&2
        return 1
    fi
}

legion_resolve_rate_settings() {
    local preset="${LEGION_RATE_PRESET:-balanced}"
    local defaults
    local default_reputation=""
    local default_profession=""
    local default_xp=""

    if [[ "$preset" == "custom" ]]; then
        : "${LEGION_RATE_REPUTATION:?LEGION_RATE_REPUTATION is required for the custom rate preset}"
        : "${LEGION_RATE_PROFESSION:?LEGION_RATE_PROFESSION is required for the custom rate preset}"
        : "${LEGION_RATE_XP:?LEGION_RATE_XP is required for the custom rate preset}"
    else
        defaults="$(legion_rate_preset_values "$preset")" || {
            printf 'Unknown LEGION_RATE_PRESET: %s\n' "$preset" >&2
            printf 'Choose blizzlike, balanced, accelerated, or custom.\n' >&2
            return 1
        }
        IFS=$'\t' read -r default_reputation default_profession default_xp <<<"$defaults"
        LEGION_RATE_REPUTATION="${LEGION_RATE_REPUTATION:-$default_reputation}"
        LEGION_RATE_PROFESSION="${LEGION_RATE_PROFESSION:-$default_profession}"
        LEGION_RATE_XP="${LEGION_RATE_XP:-$default_xp}"
    fi

    legion_validate_decimal_rate "$LEGION_RATE_REPUTATION" reputation 10
    legion_validate_profession_rate "$LEGION_RATE_PROFESSION"
    legion_validate_decimal_rate "$LEGION_RATE_XP" XP 5

    LEGION_RATE_PRESET="$preset"
    export LEGION_RATE_PRESET LEGION_RATE_REPUTATION LEGION_RATE_PROFESSION LEGION_RATE_XP
}
