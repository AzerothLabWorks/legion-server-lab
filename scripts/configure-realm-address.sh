#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: bash scripts/configure-realm-address.sh ADDRESS [options]

Set the IPv4 address or DNS hostname advertised to Legion clients.

Examples:
  bash scripts/configure-realm-address.sh 127.0.0.1
  bash scripts/configure-realm-address.sh 192.168.1.50

Options:
  --enable-lan-rest  Expose REST port 8081 on all host interfaces
  --local-rest       Bind REST port 8081 to this host only
  --no-apply         Update .env without changing a running database
  --help             Show this help
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_root/.env"
apply_now=1
rest_bind_address=""

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

[[ "$#" -ge 1 ]] || {
    usage >&2
    exit 1
}

address="$1"
shift
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --enable-lan-rest)
            rest_bind_address="0.0.0.0"
            shift
            ;;
        --local-rest)
            rest_bind_address="127.0.0.1"
            shift
            ;;
        --no-apply)
            apply_now=0
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ ! "$address" =~ ^[A-Za-z0-9][A-Za-z0-9.-]{0,252}[A-Za-z0-9]$ ]] && \
    [[ ! "$address" =~ ^[A-Za-z0-9]$ ]]; then
    echo "Invalid realm address: $address" >&2
    echo "Use an IPv4 address or DNS hostname containing only letters, digits, dots, and hyphens." >&2
    exit 1
fi

[[ -f "$env_file" ]] || {
    echo "Missing $env_file; run the installer first." >&2
    exit 1
}

temp_file="$(mktemp "$repo_root/.env.realm.XXXXXX")"
cleanup() {
    rm -f -- "$temp_file"
}
trap cleanup EXIT

awk -v address="$address" -v rest_bind_address="$rest_bind_address" '
    BEGIN { found = 0; found_rest = 0 }
    /^LEGION_REALM_ADDRESS=/ {
        print "LEGION_REALM_ADDRESS=\"" address "\""
        found = 1
        next
    }
    /^LEGION_REST_BIND_ADDRESS=/ {
        if (rest_bind_address != "")
            print "LEGION_REST_BIND_ADDRESS=\"" rest_bind_address "\""
        else
            print
        found_rest = 1
        next
    }
    { print }
    END {
        if (!found)
            print "LEGION_REALM_ADDRESS=\"" address "\""
        if (rest_bind_address != "" && !found_rest)
            print "LEGION_REST_BIND_ADDRESS=\"" rest_bind_address "\""
    }
' "$env_file" > "$temp_file"

chmod 600 "$temp_file"
mv "$temp_file" "$env_file"
trap - EXIT

echo "Saved LEGION_REALM_ADDRESS=$address"
if [[ -n "$rest_bind_address" ]]; then
    echo "Saved LEGION_REST_BIND_ADDRESS=$rest_bind_address"
    if [[ "$rest_bind_address" == "0.0.0.0" ]]; then
        echo "REST port 8081 will be reachable from the LAN after the bnetserver container is recreated."
    else
        echo "REST port 8081 will be limited to this host after the bnetserver container is recreated."
    fi
fi

if [[ "$apply_now" -eq 1 ]]; then
    bash "$repo_root/scripts/apply-required-updates.sh"
    if [[ -n "$rest_bind_address" ]]; then
        cd "$repo_root"
        docker compose up -d --force-recreate bnetserver worldserver
    fi
else
    echo "Database update skipped. The installer will apply the address on its next run."
fi
