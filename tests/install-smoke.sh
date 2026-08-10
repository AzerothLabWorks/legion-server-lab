#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$repo_root/install/install.sh"
bootstrap="$repo_root/install/bootstrap.sh"

bash -n "$installer"
bash -n "$bootstrap"
bash -n "$repo_root/scripts/init-local-env.sh"

help_output="$(bash "$installer" --help)"
grep -q 'Usage: bash install/install.sh' <<< "$help_output"
grep -q -- '--data-source PATH' <<< "$help_output"
grep -q 'does not download or distribute' "$installer"
grep -q 'exec bash.*install/install.sh' "$bootstrap"
grep -q '7.3.5.26365' "$repo_root/docs/COMMUNITY_INSTALL.md"

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

echo "community installer smoke checks passed"
