#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$repo_root/.env" ]]; then
    echo "Missing $repo_root/.env; run install/install.sh first." >&2
    exit 1
fi

set -a
# shellcheck disable=SC1091
source "$repo_root/.env"
set +a

report_dir="${LEGION_SUPPORT_REPORT_DIR:-$LEGION_RUNTIME_ROOT/logs}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$report_dir/support-report-$timestamp.txt"
mkdir -p "$report_dir"

{
    echo "AzerothLabWorks Legion Server Lab support report"
    echo "Generated: $timestamp"
    echo
    echo "== Host =="
    uname -a
    if [[ -r /etc/os-release ]]; then
        grep -E '^(NAME|VERSION|ID|ID_LIKE)=' /etc/os-release || true
    fi
    echo
    echo "== Project =="
    echo "Repository: $repo_root"
    git -C "$repo_root" rev-parse HEAD 2>/dev/null || true
    git -C "$repo_root" status --short 2>/dev/null || true
    echo
    echo "== Docker =="
    docker --version 2>&1 || true
    docker compose version 2>&1 || true
    docker buildx version 2>&1 || true
    echo
    echo "== Storage =="
    df -h "$LEGION_RUNTIME_ROOT" 2>&1 || true
    for tree in dbc maps vmaps mmaps; do
        if [[ -d "$LEGION_DATA_ROOT/$tree" ]]; then
            count="$(find "$LEGION_DATA_ROOT/$tree" -type f 2>/dev/null | wc -l)"
            size="$(du -sh "$LEGION_DATA_ROOT/$tree" 2>/dev/null | awk '{ print $1 }')"
            printf '%-5s %8s files  %s\n' "$tree" "$count" "$size"
        else
            printf '%-5s MISSING\n' "$tree"
        fi
    done
    echo
    echo "== Container status =="
    cd "$repo_root"
    docker compose ps 2>&1 || true
    echo
    echo "== Recent service logs =="
    docker compose logs --no-color --tail=200 mysql bnetserver worldserver 2>&1 || true
} > "$report"

echo "Support report created: $report"
echo "Review it for character names, account names, IP addresses, or other private"
echo "details before attaching it to an issue or sharing it in a community channel."
