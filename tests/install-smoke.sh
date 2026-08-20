#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$repo_root/install/install.sh"
bootstrap="$repo_root/install/bootstrap.sh"

bash -n "$installer"
bash -n "$bootstrap"
bash -n "$repo_root/scripts/init-local-env.sh"
bash -n "$repo_root/scripts/preflight.sh"
bash -n "$repo_root/scripts/wait-for-worldserver.sh"
bash -n "$repo_root/scripts/server-launcher.sh"
bash -n "$repo_root/scripts/support-report.sh"
bash -n "$repo_root/scripts/verify-managed-source.sh"
bash -n "$repo_root/scripts/write-managed-source-manifest.sh"
bash -n "$repo_root/scripts/configure-realm-address.sh"

help_output="$(bash "$installer" --help)"
grep -q 'Usage: bash install/install.sh' <<< "$help_output"
grep -q -- '--data-source PATH' <<< "$help_output"
grep -q -- '--client-dir PATH' <<< "$help_output"
grep -q -- '--client-build N' <<< "$help_output"
grep -q -- '--check' <<< "$help_output"
grep -q 'Set the IPv4 address or DNS hostname' \
    < <(bash "$repo_root/scripts/configure-realm-address.sh" --help)
grep -q 'does not download or distribute' "$installer"
grep -q 'exec bash.*install/install.sh' "$bootstrap"
grep -q '7.3.5 build 26365' "$repo_root/docs/COMMUNITY_INSTALL.md"
grep -q 'WSL2 Clean-Machine Installation' "$repo_root/HOWTO-WINDOWS-WSL2.md"
grep -q 'Legion 7.3.5 on Steam Deck' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'SET portal "127.0.0.1"' "$repo_root/HOWTO-STEAM-DECK.md"
if grep -qi 'WSL' "$repo_root/HOWTO-STEAM-DECK.md"; then
    echo "Steam Deck guide must remain independent of WSL" >&2
    exit 1
fi
grep -q 'SteamOS/Arch Linux environment detected' "$repo_root/scripts/preflight.sh"
grep -q 'Ubuntu WSL2 environment detected' "$repo_root/scripts/preflight.sh"
grep -q 'docker-buildx' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'Existing WoTLK or Docker setup: take the fast path' \
    "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'sudo -v' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q '| Playable client |' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'Before you start: confirm these four things' \
    "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'Client-derived data' "$repo_root/docs/DISTRIBUTION_BOUNDARY.md"
grep -q 'Legion 7.3.5 Client and Data Prerequisites' \
    "$repo_root/docs/CLIENT_SETUP.md"
grep -q 'LEGION SERVER READY' "$repo_root/docs/CLIENT_SETUP.md"
grep -q 'permission-restricted runtime file' "$repo_root/docs/CLIENT_SETUP.md"
grep -q 'third-party binaries' "$repo_root/docs/CLIENT_SETUP.md"
grep -q 'docs/CLIENT_SETUP.md' "$repo_root/install/install.sh"
grep -q 'LEGION SERVER READY' "$repo_root/scripts/wait-for-worldserver.sh"
grep -q 'This Legion build does not currently include a viable Playerbots module' \
    "$repo_root/install/install.sh"
test -f "$repo_root/LICENSE"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
mkdir -p "$tmp_root/seed/install" "$tmp_root/home"
cat > "$tmp_root/seed/install/install.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$BOOTSTRAP_TEST_OUTPUT"
EOF
git -C "$tmp_root/seed" init -q
git -C "$tmp_root/seed" add install/install.sh
git -C "$tmp_root/seed" -c user.name=test -c user.email=test@example.invalid commit -qm seed

BOOTSTRAP_TEST_OUTPUT="$tmp_root/bootstrap-args" \
HOME="$tmp_root/home" \
LEGION_LAB_DIR="$tmp_root/target" \
LEGION_LAB_REPO_URL="$tmp_root/seed" \
    bash "$bootstrap" --data-source /tmp/example-data >/dev/null

grep -q -- '--data-source /tmp/example-data' "$tmp_root/bootstrap-args"
test -d "$tmp_root/target/.git"

mkdir -p "$tmp_root/client/Data"
touch "$tmp_root/client/WoW-Legion-64bit.exe"
mkdir -p "$tmp_root/server-data"/{dbc,maps,vmaps,mmaps}
for tree in dbc maps vmaps mmaps; do
    touch "$tmp_root/server-data/$tree/test-file"
done
client_check_output="$(
    LEGION_MIN_FREE_GB=0 bash "$installer" --check \
        --client-dir "$tmp_root/client" --client-build 26365 \
        --data-source "$tmp_root/server-data"
)"
grep -q 'reported login-screen build: 26365' <<< "$client_check_output"
grep -q 'will not be copied or modified' <<< "$client_check_output"
grep -q 'Compatible server-data directory structure supplied' <<< "$client_check_output"
grep -q 'No source, runtime, client, or data files were modified' <<< "$client_check_output"
mkdir -p "$tmp_root/incomplete-data"/{dbc,maps,vmaps}
if LEGION_MIN_FREE_GB=0 bash "$installer" --check \
    --data-source "$tmp_root/incomplete-data" >/dev/null 2>&1; then
    echo "Incomplete server-data tree was accepted" >&2
    exit 1
fi
if LEGION_MIN_FREE_GB=0 bash "$installer" --check \
    --client-dir "$tmp_root/client" --client-build 12340 >/dev/null 2>&1; then
    echo "Unsupported client build was accepted" >&2
    exit 1
fi
if LEGION_MIN_FREE_GB=0 bash "$installer" --check \
    --client-dir "$tmp_root/client" >/dev/null 2>&1; then
    echo "Client directory without a build was accepted" >&2
    exit 1
fi
if LEGION_MIN_FREE_GB=0 bash "$installer" --check \
    --client-build 26365 >/dev/null 2>&1; then
    echo "Client build without a directory was accepted" >&2
    exit 1
fi

mkdir -p "$tmp_root/realm-test/scripts"
cp "$repo_root/scripts/configure-realm-address.sh" \
    "$tmp_root/realm-test/scripts/configure-realm-address.sh"
cat > "$tmp_root/realm-test/.env" <<'EOF'
LEGION_DB_ROOT_PASSWORD="fixture-only"
LEGION_REALM_ADDRESS="127.0.0.1"
LEGION_REST_BIND_ADDRESS="127.0.0.1"
EOF
bash "$tmp_root/realm-test/scripts/configure-realm-address.sh" \
    192.168.1.50 --enable-lan-rest --no-apply >/dev/null
grep -q 'LEGION_REALM_ADDRESS="192.168.1.50"' "$tmp_root/realm-test/.env"
grep -q 'LEGION_REST_BIND_ADDRESS="0.0.0.0"' "$tmp_root/realm-test/.env"
bash "$tmp_root/realm-test/scripts/configure-realm-address.sh" \
    127.0.0.1 --local-rest --no-apply >/dev/null
grep -q 'LEGION_REALM_ADDRESS="127.0.0.1"' "$tmp_root/realm-test/.env"
grep -q 'LEGION_REST_BIND_ADDRESS="127.0.0.1"' "$tmp_root/realm-test/.env"
if bash "$tmp_root/realm-test/scripts/configure-realm-address.sh" \
    "bad'address" --no-apply >/dev/null 2>&1; then
    echo "Unsafe realm address was accepted" >&2
    exit 1
fi

echo "community installer smoke checks passed"
