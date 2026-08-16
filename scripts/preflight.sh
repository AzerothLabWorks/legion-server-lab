#!/usr/bin/env bash
set -euo pipefail

MIN_FREE_GB="${LEGION_MIN_FREE_GB:-50}"
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
    fail "Run this installer inside Ubuntu/WSL2 or another x86-64 Linux environment."
else
    ok "Linux environment detected"
fi

case "$(uname -m)" in
    x86_64|amd64) ok "x86-64 architecture detected" ;;
    *) fail "Unsupported architecture: $(uname -m). This pinned core is tested on x86-64." ;;
esac

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    if grep -qi wsl2 /proc/sys/kernel/osrelease 2>/dev/null; then
        ok "WSL2 kernel detected"
    else
        warn "A Microsoft WSL kernel was detected, but WSL2 could not be confirmed."
    fi
else
    warn "WSL2 was not detected. Native x86-64 Linux can work, but the community guide tests WSL2."
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

    if docker info >/dev/null 2>&1; then
        ok "Docker daemon is responding"
    else
        fail "Docker is installed but not responding. Start Docker Desktop or Docker Engine."
    fi
fi

if [[ -d "$HOME" ]]; then
    available_kb="$(df -Pk "$HOME" | awk 'NR == 2 { print $4 }')"
    if [[ "$available_kb" =~ ^[0-9]+$ ]]; then
        available_gb=$((available_kb / 1024 / 1024))
        if (( available_gb < MIN_FREE_GB )); then
            warn "Only ${available_gb} GiB is free on the WSL filesystem; ${MIN_FREE_GB} GiB is recommended for a clean install."
        else
            ok "${available_gb} GiB free on the WSL filesystem"
        fi
    fi
fi

if (( errors > 0 )); then
    printf '\nPreflight failed with %d error(s).\n' "$errors" >&2
    exit 1
fi

printf '\nLegion server preflight passed.\n'
