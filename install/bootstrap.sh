#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${LEGION_LAB_REPO_URL:-https://github.com/AzerothLabWorks/legion-server-lab.git}"
LAB_DIR="${LEGION_LAB_DIR:-$HOME/legion-server-lab}"

command -v git >/dev/null 2>&1 || {
    echo "ERROR: git is required." >&2
    exit 1
}

if [[ -d "$LAB_DIR/.git" ]]; then
    if [[ -n "$(git -C "$LAB_DIR" status --porcelain)" ]]; then
        echo "ERROR: Existing lab checkout has local changes: $LAB_DIR" >&2
        exit 1
    fi
    git -C "$LAB_DIR" pull --ff-only
elif [[ -e "$LAB_DIR" ]]; then
    echo "ERROR: $LAB_DIR exists but is not a Git checkout." >&2
    exit 1
else
    git clone "$REPO_URL" "$LAB_DIR"
fi

exec bash "$LAB_DIR/install/install.sh" "$@"
