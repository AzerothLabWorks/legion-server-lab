#!/usr/bin/env bash
set -euo pipefail

CORE_URL="${LEGION_CORE_URL:-https://github.com/Legion-Pandaria-Preservation-Project/LegionCore-7.3.5V2.git}"
CORE_COMMIT="6c41d0faa23474bf9e76a4811b144d43e9545bab"
SOURCE_ROOT="${LEGION_SOURCE_ROOT:-$HOME/legion-server-sources}"
SOURCE_DIR="${LEGION_SOURCE_DIR:-$SOURCE_ROOT/LegionCore-7.3.5V2}"
RUNTIME_ROOT="${LEGION_RUNTIME_ROOT:-$HOME/legion-server-runtime}"
DATA_SOURCE="${LEGION_DATA_SOURCE:-}"
CLIENT_DIR="${LEGION_CLIENT_DIR:-}"
CLIENT_BUILD="${LEGION_CLIENT_BUILD:-}"
SKIP_BUILD=0
START_SERVER=1
CHECK_ONLY=0

usage() {
    cat <<'USAGE'
Usage: bash install/install.sh [options]

Build and prepare the AzerothLabWorks Legion 7.3.5 server on Steam Deck.

Options:
  --client-dir PATH   Validate an operator-supplied playable client (read-only)
  --client-build N    Report the login-screen build; must be 26365
  --data-source PATH  Copy user-supplied build-26365 dbc/maps/vmaps/mmaps data
  --skip-build        Reuse an existing compiled server under the runtime root
  --no-start          Prepare everything but do not start Docker services
  --check             Check SteamOS/Arch, Docker, tools, and disk space; change nothing
  --help              Show this help

Environment overrides:
  LEGION_SOURCE_ROOT, LEGION_SOURCE_DIR, LEGION_RUNTIME_ROOT,
  LEGION_DATA_SOURCE, LEGION_CLIENT_DIR, LEGION_CLIENT_BUILD,
  LEGION_BUILD_JOBS, LEGION_CORE_URL

Recommended community invocation:
  bash install/install.sh \
    --client-dir /home/deck/Games/WoW-7.3.5-Legion \
    --client-build 26365 \
    --data-source /home/deck/Games/LegionData/Data

The playable client is checked in place and is never copied or modified.
USAGE
}

info() {
    printf '%s\n' "$*"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

have() {
    command -v "$1" >/dev/null 2>&1
}

canonical_path() {
    if have realpath; then
        realpath "$1"
    else
        (cd "$1" && pwd -P)
    fi
}

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --client-dir)
                [[ "$#" -ge 2 ]] || die "--client-dir requires a path"
                CLIENT_DIR="$2"
                shift 2
                ;;
            --client-build)
                [[ "$#" -ge 2 ]] || die "--client-build requires a number"
                CLIENT_BUILD="$2"
                shift 2
                ;;
            --data-source)
                [[ "$#" -ge 2 ]] || die "--data-source requires a path"
                DATA_SOURCE="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=1
                shift
                ;;
            --no-start)
                START_SERVER=0
                shift
                ;;
            --check)
                CHECK_ONLY=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

validate_client_info() {
    if [[ -z "$CLIENT_DIR" && -z "$CLIENT_BUILD" ]]; then
        cat <<'EOF'
[info] No playable-client metadata was supplied. Continuing as a server-only install.
       Community users should read docs/CLIENT_SETUP.md and normally provide:
         --client-dir PATH --client-build 26365
EOF
        return 0
    fi

    [[ -n "$CLIENT_DIR" ]] || die "--client-build requires --client-dir."
    [[ -n "$CLIENT_BUILD" ]] || die "--client-dir requires --client-build 26365."
    [[ "$CLIENT_BUILD" =~ ^[0-9]+$ ]] || die "Client build must be numeric: $CLIENT_BUILD"
    [[ "$CLIENT_BUILD" == "26365" ]] || die "Unsupported client build $CLIENT_BUILD; this lab requires 7.3.5.26365 x64."
    [[ -d "$CLIENT_DIR" ]] || die "Playable client directory not found: $CLIENT_DIR"
    [[ -d "$CLIENT_DIR/Data" ]] || die "Playable client has no Data directory: $CLIENT_DIR/Data"

    local client_path executable
    client_path="$(canonical_path "$CLIENT_DIR")"
    executable="$(find "$client_path" -maxdepth 1 -type f \
        \( -iname '*wow*64*.exe' -o -iname 'wow-64.exe' \) \
        -print -quit 2>/dev/null || true)"

    info "Playable-client prerequisite supplied:"
    info "  location: $client_path"
    info "  reported login-screen build: $CLIENT_BUILD"
    if [[ -n "$executable" ]]; then
        info "  x64 executable candidate: $(basename "$executable")"
    else
        info "  WARNING: no conventionally named x64 WoW executable was found at the client root."
        info "           Client filenames vary; confirm 'Release x64' on the login screen."
    fi
    info "  action: validation only; the playable client will not be copied or modified"
}

prepare_source() {
    mkdir -p "$SOURCE_ROOT"
    if [[ ! -d "$SOURCE_DIR/.git" ]]; then
        [[ ! -e "$SOURCE_DIR" ]] || die "$SOURCE_DIR exists but is not a Git checkout."
        info "Cloning the open-source LegionCore server..."
        git clone "$CORE_URL" "$SOURCE_DIR"
    fi

    if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain)" ]]; then
        [[ "$(git -C "$SOURCE_DIR" rev-parse HEAD)" == "$CORE_COMMIT" ]] || die "Source checkout has local changes on an unexpected revision: $SOURCE_DIR"
        LEGION_SOURCE_DIR="$SOURCE_DIR" bash "$REPO_ROOT/scripts/verify-managed-source.sh" || \
            die "Source checkout contains changes not managed by this installer: $SOURCE_DIR"
        info "Reusing the installer-managed patched source checkout."
        return 0
    fi

    git -C "$SOURCE_DIR" fetch origin "$CORE_COMMIT"
    git -C "$SOURCE_DIR" checkout --detach "$CORE_COMMIT"
}

prepare_environment() {
    export LEGION_RUNTIME_ROOT="$RUNTIME_ROOT"
    export LEGION_DATA_ROOT="$RUNTIME_ROOT/data"

    if [[ ! -f "$REPO_ROOT/.env" ]]; then
        LEGION_RUNTIME_ROOT="$LEGION_RUNTIME_ROOT" \
        LEGION_DATA_ROOT="$LEGION_DATA_ROOT" \
            bash "$REPO_ROOT/scripts/init-local-env.sh"
    fi

    set -a
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.env"
    set +a

    [[ "$LEGION_RUNTIME_ROOT" == "$RUNTIME_ROOT" ]] || die ".env runtime root differs from requested root: $LEGION_RUNTIME_ROOT"
    mkdir -p "$LEGION_RUNTIME_ROOT/data"
}

validate_data_tree() {
    local root="$1"
    local tree
    for tree in dbc maps vmaps mmaps; do
        [[ -d "$root/$tree" ]] || return 1
        [[ -n "$(find "$root/$tree" -type f -print -quit 2>/dev/null)" ]] || return 1
    done
}

describe_data_tree() {
    local root="$1"
    local tree file_count size
    for tree in dbc maps vmaps mmaps; do
        file_count="$(find "$root/$tree" -type f 2>/dev/null | wc -l)"
        size="$(du -sh "$root/$tree" 2>/dev/null | awk '{ print $1 }')"
        printf '  %-5s %8s files  %s\n' "$tree" "$file_count" "$size"
    done
}

install_data() {
    if [[ -n "$DATA_SOURCE" ]]; then
        [[ -d "$DATA_SOURCE" ]] || die "Data source directory not found: $DATA_SOURCE"
        validate_data_tree "$DATA_SOURCE" || die "Data source must contain dbc, maps, vmaps, and mmaps directories."

        info "Validated the four required client-derived data trees:"
        describe_data_tree "$DATA_SOURCE"

        local source_path target_path
        source_path="$(canonical_path "$DATA_SOURCE")"
        target_path="$(canonical_path "$LEGION_DATA_ROOT")"
        if [[ "$source_path" != "$target_path" ]]; then
            info "Copying client-derived data into native Linux storage. This can take several minutes..."
            cp -a "$source_path/." "$target_path/"
        fi
    fi

    validate_data_tree "$LEGION_DATA_ROOT"
}

build_and_prepare() {
    if [[ "$SKIP_BUILD" -eq 0 ]]; then
        LEGION_SOURCE_DIR="$SOURCE_DIR" bash "$REPO_ROOT/scripts/build-core.sh"
    elif [[ ! -x "$LEGION_RUNTIME_ROOT/server/bin/worldserver" ]]; then
        die "--skip-build requested, but no compiled worldserver was found."
    fi

    LEGION_SOURCE_ROOT="$SOURCE_DIR" bash "$REPO_ROOT/scripts/prepare-runtime.sh"
}

wait_for_mysql() {
    local container health
    for _ in $(seq 1 180); do
        container="$(docker compose ps -q mysql)"
        if [[ -n "$container" ]]; then
            health="$(docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null || true)"
            [[ "$health" == "healthy" ]] && return 0
        fi
        sleep 5
    done
    return 1
}

start_server() {
    cd "$REPO_ROOT"
    docker compose up -d mysql
    info "Waiting for the initial MySQL import and health check..."
    wait_for_mysql || die "MySQL did not become healthy. Run: docker compose logs mysql"
    bash "$REPO_ROOT/scripts/apply-required-updates.sh"
    docker compose up -d bnetserver worldserver
    docker compose ps
}

main() {
    parse_args "$@"
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    bash "$REPO_ROOT/scripts/preflight.sh"
    validate_client_info
    [[ "$CHECK_ONLY" -eq 0 ]] || exit 0
    prepare_source
    prepare_environment
    build_and_prepare

    if ! install_data; then
        cat <<EOF

Server build and database preparation completed, but the server was not started.

Supply legally obtained, client-derived build-26365 data containing:
  dbc/  maps/  vmaps/  mmaps/

Then rerun:
  bash install/install.sh --skip-build --data-source /absolute/path/to/Data

The project does not download or distribute World of Warcraft clients or
client-derived game data.

Read the client and data checklist before resuming:
  docs/CLIENT_SETUP.md
EOF
        exit 2
    fi

    if [[ "$START_SERVER" -eq 1 ]]; then
        start_server
        info "Installation completed. Continue with HOWTO-STEAM-DECK.md."
    else
        info "Preparation completed. Start later with: bash scripts/compose.sh up -d mysql bnetserver worldserver"
    fi
}

main "$@"
