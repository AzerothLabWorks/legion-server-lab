#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="${LEGION_SOURCE_DIR:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
expected_commit="6c41d0faa23474bf9e76a4811b144d43e9545bab"

[[ -d "$source_dir/.git" ]] || {
    echo "Source checkout not found: $source_dir" >&2
    exit 1
}

[[ "$(git -C "$source_dir" rev-parse HEAD)" == "$expected_commit" ]] || {
    echo "Source checkout is not at the pinned revision." >&2
    exit 1
}

verify_root="$(mktemp -d /tmp/legion-managed-source.XXXXXX)"
cleanup() {
    case "$verify_root" in
        /tmp/legion-managed-source.*) rm -rf -- "$verify_root" ;;
        *) echo "Refusing to remove unexpected verification path: $verify_root" >&2 ;;
    esac
}
trap cleanup EXIT

saved_manifest="$(git -C "$source_dir" rev-parse --git-path azerothlabworks-managed-source.sha256)"
if [[ -f "$saved_manifest" ]]; then
    actual_manifest="$verify_root/actual-manifest"
    LEGION_SOURCE_DIR="$source_dir" LEGION_MANAGED_MANIFEST="$actual_manifest" \
        bash "$repo_root/scripts/write-managed-source-manifest.sh" >/dev/null

    if cmp -s "$saved_manifest" "$actual_manifest"; then
        echo "Previously recorded installer-managed source verification passed"
        exit 0
    fi

    echo "Source files changed after the last installer-managed build:" >&2
    diff -u "$saved_manifest" "$actual_manifest" >&2 || true
    exit 1
fi

expected="$verify_root/expected"
git clone -q --shared "$source_dir" "$expected"
git -C "$expected" reset -q --hard "$expected_commit"

for patch_file in "$repo_root"/patches/*.patch; do
    git -C "$expected" apply "$patch_file"
done

install -m 0644 "$repo_root/overlays/companion_autoloot.cpp" \
    "$expected/src/server/scripts/Custom/companion_autoloot.cpp"
install -m 0644 "$repo_root/overlays/startup_qol.cpp" \
    "$expected/src/server/scripts/Custom/startup_qol.cpp"
install -m 0644 "$repo_root/overlays/rocket_rescue.cpp" \
    "$expected/src/server/scripts/Custom/rocket_rescue.cpp"

status_paths() {
    git -C "$1" status --porcelain --untracked-files=all \
        | sed -E 's/^...//' \
        | LC_ALL=C sort
}

status_paths "$source_dir" > "$verify_root/actual-paths"
status_paths "$expected" > "$verify_root/expected-paths"
LC_ALL=C sort -u "$verify_root/actual-paths" "$verify_root/expected-paths" \
    > "$verify_root/all-paths"

while IFS= read -r relative_path; do
    [[ -n "$relative_path" ]] || continue
    if [[ ! -f "$source_dir/$relative_path" ]] || [[ ! -f "$expected/$relative_path" ]]; then
        echo "Unexpected added or removed source file: $relative_path" >&2
        exit 1
    fi

    # Some editors add the POSIX final newline to old upstream files. Treat
    # that and other end-of-line-only differences as equivalent, but reject
    # every substantive source change.
    if ! cmp -s "$source_dir/$relative_path" "$expected/$relative_path" && \
        ! git diff --no-index --ignore-space-at-eol --quiet -- \
            "$source_dir/$relative_path" "$expected/$relative_path"; then
        echo "Managed source file differs: $relative_path" >&2
        git diff --no-index -- "$expected/$relative_path" \
            "$source_dir/$relative_path" >&2 || true
        exit 1
    fi
done < "$verify_root/all-paths"

echo "Installer-managed source verification passed"
