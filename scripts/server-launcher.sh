#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
action="${1:-start}"

cd "$repo_root"

case "$action" in
    start)
        echo "Starting the Legion database, login server, and world server..."
        bash "$repo_root/scripts/compose.sh" up -d mysql bnetserver worldserver
        bash "$repo_root/scripts/wait-for-worldserver.sh"
        echo
        bash "$repo_root/scripts/compose.sh" ps
        echo
        echo "Leave the Docker services running and launch the Legion client."
        echo "When finished, run: $HOME/legion-server-launcher.sh stop"
        ;;
    stop)
        echo "Stopping the Legion server cleanly..."
        bash "$repo_root/scripts/compose.sh" down
        ;;
    status)
        bash "$repo_root/scripts/compose.sh" ps
        ;;
    logs)
        bash "$repo_root/scripts/compose.sh" logs -f bnetserver worldserver
        ;;
    *)
        echo "Usage: $0 [start|stop|status|logs]" >&2
        exit 1
        ;;
esac
