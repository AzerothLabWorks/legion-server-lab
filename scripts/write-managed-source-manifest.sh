#!/usr/bin/env bash
set -euo pipefail

source_dir="${LEGION_SOURCE_DIR:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
expected_commit="6c41d0faa23474bf9e76a4811b144d43e9545bab"

[[ -d "$source_dir/.git" ]] || {
    echo "Source checkout not found: $source_dir" >&2
    exit 1
}

[[ "$(git -C "$source_dir" rev-parse HEAD)" == "$expected_commit" ]] || {
    echo "Cannot record a managed manifest for an unpinned source revision." >&2
    exit 1
}

manifest="${LEGION_MANAGED_MANIFEST:-$(git -C "$source_dir" rev-parse --git-path azerothlabworks-managed-source.sha256)}"
manifest_dir="$(dirname "$manifest")"
mkdir -p "$manifest_dir"
temp_manifest="$(mktemp "$manifest_dir/.managed-source.XXXXXX")"

cleanup() {
    rm -f -- "$temp_manifest"
}
trap cleanup EXIT

git -C "$source_dir" status --porcelain --untracked-files=all \
    | sed -E 's/^...//' \
    | LC_ALL=C sort \
    | while IFS= read -r relative_path; do
        [[ -n "$relative_path" ]] || continue
        if [[ -f "$source_dir/$relative_path" ]]; then
            hash="$(sha256sum "$source_dir/$relative_path" | awk '{ print $1 }')"
            printf '%s  %s\n' "$hash" "$relative_path"
        else
            printf 'DELETED  %s\n' "$relative_path"
        fi
    done > "$temp_manifest"

mv "$temp_manifest" "$manifest"
trap - EXIT
echo "Recorded installer-managed source manifest: $manifest"
