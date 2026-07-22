#!/usr/bin/env bash
# lib/podman.sh — Podman container management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

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
    while [[ $attempts -lt $max_attempts ]]; do
        if podman exec "$CONTAINER_NAME" bash -c "echo 'SELECT 1 FROM DUAL;' | sqlplus -s / as sysdba" 2>/dev/null | grep -q '1'; then
            log_ok "Oracle is ready"
            return 0
        fi
        ((attempts++))
        sleep 2
    done
    log_err "Oracle failed to become ready after ${max_attempts} attempts"
    return 1
}
