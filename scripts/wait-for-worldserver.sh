#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
timeout_seconds="${LEGION_WORLD_READY_TIMEOUT:-1200}"
poll_seconds="${LEGION_WORLD_READY_POLL:-5}"
ready_marker="(worldserver-daemon) ready..."

if [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    echo "LEGION_WORLD_READY_TIMEOUT must be a positive number of seconds." >&2
    exit 1
fi

if [[ ! "$poll_seconds" =~ ^[1-9][0-9]*$ ]]; then
    echo "LEGION_WORLD_READY_POLL must be a positive number of seconds." >&2
    exit 1
fi

cd "$repo_root"

if [[ ! -f .env ]]; then
    echo "Missing $repo_root/.env; run install/install.sh first." >&2
    exit 1
fi

if (( timeout_seconds < 60 )); then
    echo "Waiting up to $timeout_seconds seconds for the Legion world server..."
else
    echo "Waiting up to $((timeout_seconds / 60)) minutes for the Legion world server..."
fi

elapsed=0
while (( elapsed < timeout_seconds )); do
    container_id="$(docker compose ps -q worldserver 2>/dev/null || true)"

    if [[ -n "$container_id" ]]; then
        container_status="$(docker inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
        container_started="$(docker inspect -f '{{.State.StartedAt}}' "$container_id" 2>/dev/null || true)"
        if [[ "$container_status" == "exited" || "$container_status" == "dead" ]]; then
            echo "The worldserver container stopped before becoming ready." >&2
            docker compose logs --no-color --tail=100 worldserver >&2 || true
            exit 1
        fi

        recent_logs="$(docker compose logs --no-color --since "$container_started" worldserver 2>&1 || true)"
        if grep -Fq "$ready_marker" <<< "$recent_logs"; then
            echo "LEGION SERVER READY"
            echo "The client may now connect to 127.0.0.1."
            exit 0
        fi
    fi

    sleep "$poll_seconds"
    elapsed=$((elapsed + poll_seconds))
done

echo "The world server did not report ready within $timeout_seconds seconds." >&2
echo "Recent worldserver output:" >&2
docker compose logs --no-color --tail=100 worldserver >&2 || true
exit 1
