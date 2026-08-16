#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$repo_root/install/install.sh"
bootstrap="$repo_root/install/bootstrap.sh"

bash -n "$installer"
bash -n "$bootstrap"
bash -n "$repo_root/scripts/init-local-env.sh"
bash -n "$repo_root/scripts/preflight.sh"
bash -n "$repo_root/scripts/verify-managed-source.sh"
bash -n "$repo_root/scripts/write-managed-source-manifest.sh"
bash -n "$repo_root/scripts/configure-realm-address.sh"

help_output="$(bash "$installer" --help)"
grep -q 'Usage: bash install/install.sh' <<< "$help_output"
grep -q -- '--data-source PATH' <<< "$help_output"
grep -q -- '--check' <<< "$help_output"
grep -q 'Set the IPv4 address or DNS hostname' \
    < <(bash "$repo_root/scripts/configure-realm-address.sh" --help)
grep -q 'does not download or distribute' "$installer"
grep -q 'exec bash.*install/install.sh' "$bootstrap"
grep -q '7.3.5.26365' "$repo_root/docs/COMMUNITY_INSTALL.md"
grep -q 'WSL2 Clean-Machine Installation' "$repo_root/HOWTO-WINDOWS-WSL2.md"
grep -q 'Legion 7.3.5 on Steam Deck' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'configure-realm-address.sh' "$repo_root/HOWTO-STEAM-DECK.md"
grep -q 'Client-derived data' "$repo_root/docs/DISTRIBUTION_BOUNDARY.md"
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
