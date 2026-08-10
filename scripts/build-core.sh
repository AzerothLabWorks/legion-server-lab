#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${LEGION_SOURCE_DIR:-$HOME/legion-server-sources/LegionCore-7.3.5V2}"
BUILD_DIR="${LEGION_BUILD_DIR:-$HOME/legion-server-runtime/build-ubuntu18.04}"
INSTALL_DIR="${LEGION_INSTALL_DIR:-$HOME/legion-server-runtime/server}"
IMAGE="${LEGION_BUILD_IMAGE:-legion-server-build:ubuntu18.04}"
BUILD_JOBS="${LEGION_BUILD_JOBS:-$(nproc)}"
EXPECTED_COMMIT="6c41d0faa23474bf9e76a4811b144d43e9545bab"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    echo "Legion source checkout not found: $SOURCE_DIR" >&2
    exit 1
fi

actual_commit="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ "$actual_commit" != "$EXPECTED_COMMIT" ]]; then
    echo "Unexpected source revision: $actual_commit" >&2
    echo "Expected: $EXPECTED_COMMIT" >&2
    exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

for patch_file in "$repo_root"/patches/*.patch; do
    if git -C "$SOURCE_DIR" apply --check "$patch_file" 2>/dev/null; then
        git -C "$SOURCE_DIR" apply "$patch_file"
    elif git -C "$SOURCE_DIR" apply --reverse --check "$patch_file" 2>/dev/null; then
        : # Already applied exactly.
    elif [[ "$(basename "$patch_file")" == "0012-add-companion-autoloot.patch" ]] \
        && grep -q 'AddSC_companion_autoloot' "$SOURCE_DIR/src/server/scripts/ScriptLoader.cpp" \
        && grep -q 'CompanionAutoLoot.Enable = 0' "$SOURCE_DIR/src/server/worldserver/worldserver.conf.dist"; then
        : # Applied, then intentionally overlapped by the later startup-QoL patch.
    elif [[ "$(basename "$patch_file")" == "0013-add-startup-qol.patch" ]] \
        && grep -q 'AddSC_startup_qol' "$SOURCE_DIR/src/server/scripts/ScriptLoader.cpp" \
        && grep -q 'StartupQoL.Enable = 0' "$SOURCE_DIR/src/server/worldserver/worldserver.conf.dist"; then
        : # Already applied; its documentation-only context was subsequently refined.
    else
        echo "Patch cannot be applied cleanly: $patch_file" >&2
        exit 1
    fi
done

install -m 0644 "$repo_root/overlays/companion_autoloot.cpp" \
    "$SOURCE_DIR/src/server/scripts/Custom/companion_autoloot.cpp"
install -m 0644 "$repo_root/overlays/startup_qol.cpp" \
    "$SOURCE_DIR/src/server/scripts/Custom/startup_qol.cpp"

docker build -t "$IMAGE" "$repo_root/docker/build"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --workdir /build \
    --volume "$SOURCE_DIR:/source:ro" \
    --volume "$BUILD_DIR:/build" \
    --volume "$INSTALL_DIR:/install" \
    --env "BUILD_JOBS=$BUILD_JOBS" \
    "$IMAGE" \
    bash -lc 'cmake /source -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/install \
        -DNOPCH=0 \
        -DTOOLS=0 \
        -DWITH_WARNINGS=0 \
        && cmake --build . -- -j"$BUILD_JOBS" \
        && cmake --build . --target install'
