#!/usr/bin/env bash
# lib/podman.sh — Podman container management

set -euo pipefail

[[ -n "${ORACLE_PODMAN_SOURCED:-}" ]] && return 0
ORACLE_PODMAN_SOURCED=1

__oracle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$__oracle_lib_dir/utils.sh"

readonly ORACLE_IMAGE="container-registry.oracle.com/database/free:latest"
readonly CONTAINER_NAME="oracledb"
readonly VOLUME_NAME="oracledb_data"

# Check if Oracle container image is present
image_exists() {
    podman image exists "$ORACLE_IMAGE"
}

# Pull Oracle image if missing
pull_oracle_image() {
    if image_exists; then
        log_ok "Oracle image already present"
        return 0
    fi
    log_info "Pulling Oracle Database Free image..."
    podman pull "$ORACLE_IMAGE"
    log_ok "Oracle image pulled"
}

# Check if container exists
container_exists() {
    podman container exists "$CONTAINER_NAME"
}

# Check if container is running
container_running() {
    [[ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" == "true" ]]
}

# Create Oracle container if missing
create_container() {
    if container_exists; then
        log_ok "Oracle container already exists"
        return 0
    fi
    log_info "Creating Oracle container..."
    podman run -d \
        --name "$CONTAINER_NAME" \
        -p 1521:1521 \
        -v "${VOLUME_NAME}:/opt/oracle/oradata" \
        -e ORACLE_PDB="FREEPDB1" \
        "$ORACLE_IMAGE"
    log_ok "Oracle container created"
}

# Start container if stopped
start_container() {
    if container_running; then
        log_ok "Oracle container is running"
        return 0
    fi
    if container_exists; then
        log_info "Starting Oracle container..."
        podman start "$CONTAINER_NAME"
        log_ok "Oracle container started"
    else
        create_container
    fi
}

# Run SQL inside the container via podman exec
# Usage: container_sql "SELECT 1 FROM DUAL;"
container_sql() {
    local sql="$1"
    podman exec -i "$CONTAINER_NAME" sqlplus -s / as sysdba <<< "$sql"
}

# Wait until Oracle is accepting connections
wait_for_oracle() {
    log_info "Waiting for Oracle to be ready..."
    local attempts=0
    local max_attempts=60
    local result

    while [[ $attempts -lt $max_attempts ]]; do
        result="$(podman exec -i "$CONTAINER_NAME" sqlplus -s / as sysdba 2>&1 <<'EOF'
WHENEVER SQLERROR EXIT 1;
WHENEVER OSERROR EXIT 1;
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM v$pdbs WHERE name='FREEPDB1' AND open_mode='READ WRITE';
EXIT;
EOF
)" || true

        result="$(echo "$result" | tr -d '[:space:]')"

        if [[ "$result" == "1" ]]; then
            printf "\n"
            log_ok "Oracle is ready (PDB FREEPDB1 is open)"
            return 0
        fi
        ((attempts++))
        sleep 3
        printf "\r[>] Waiting... (%d/%d)" "$attempts" "$max_attempts"
    done
    printf "\n"
    log_err "Oracle failed to become ready after ${max_attempts} attempts"
    return 1
}
