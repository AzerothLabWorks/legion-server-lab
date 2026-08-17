#!/usr/bin/env bash
set -euo pipefail

MIN_FREE_GB="${LEGION_MIN_FREE_GB:-50}"
ALLOW_UNSUPPORTED_HOST="${LEGION_ALLOW_UNSUPPORTED_HOST:-0}"
errors=0

ok() {
    printf '[ok] %s\n' "$*"
}

warn() {
    printf '[warn] %s\n' "$*" >&2
}

fail() {
    printf '[error] %s\n' "$*" >&2
    errors=$((errors + 1))
}

have() {
    command -v "$1" >/dev/null 2>&1
}

if [[ "$(uname -s)" != "Linux" ]]; then
    fail "Run this installer on SteamOS/Arch Linux or Ubuntu under WSL2."
else
    ok "Linux environment detected"
fi

case "$(uname -m)" in
    x86_64|amd64) ok "x86-64 architecture detected" ;;
    *) fail "Unsupported architecture: $(uname -m). This pinned core is tested on x86-64." ;;
esac

os_id=""
os_like=""
os_name="unknown Linux distribution"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_id="${ID:-}"
    os_like="${ID_LIKE:-}"
    os_name="${PRETTY_NAME:-${NAME:-unknown Linux distribution}}"
fi

is_wsl2=0
if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null \
    && grep -qi wsl2 /proc/sys/kernel/osrelease 2>/dev/null; then
    is_wsl2=1
fi

if [[ " $os_id $os_like " == *" steamos "* || " $os_id $os_like " == *" arch "* ]]; then
    ok "SteamOS/Arch Linux environment detected: $os_name"
elif [[ "$is_wsl2" == "1" && " $os_id $os_like " == *" ubuntu "* ]]; then
    ok "Ubuntu WSL2 environment detected: $os_name"
elif [[ "$ALLOW_UNSUPPORTED_HOST" == "1" ]]; then
    warn "Supported hosts are Steam Deck/SteamOS and Ubuntu/WSL2; detected: $os_name"
    warn "LEGION_ALLOW_UNSUPPORTED_HOST=1 enabled for development or CI."
else
    fail "Unsupported host: $os_name. Use Steam Deck/SteamOS or Ubuntu under WSL2."
fi

for tool in git docker openssl sha256sum; do
    if have "$tool"; then
        ok "$tool is available"
    else
        fail "Required command not found: $tool"
    fi
done

if have docker; then
    if docker compose version >/dev/null 2>&1; then
        ok "Docker Compose v2 is available"
    else
        fail "Docker Compose v2 is required (the command must be: docker compose)."
    fi

    if docker buildx version >/dev/null 2>&1; then
        ok "Docker Buildx is available"
    else
        fail "Docker Buildx is required; install it for the selected host platform."
    fi

    if docker info >/dev/null 2>&1; then
        ok "Docker daemon is responding"
    else
        fail "Docker is installed but not responding. Start the Docker Engine."
    fi
fi

if [[ -d "$HOME" ]]; then
    available_kb="$(df -Pk "$HOME" | awk 'NR == 2 { print $4 }')"
    if [[ "$available_kb" =~ ^[0-9]+$ ]]; then
        available_gb=$((available_kb / 1024 / 1024))
        if (( available_gb < MIN_FREE_GB )); then
            warn "Only ${available_gb} GiB is free on the home filesystem; ${MIN_FREE_GB} GiB is recommended for a clean install."
        else
            ok "${available_gb} GiB free on the home filesystem"
        fi
    fi
fi

if (( errors > 0 )); then
    printf '\nPreflight failed with %d error(s).\n' "$errors" >&2
    exit 1
fi

printf '\nLegion server preflight passed.\n'
