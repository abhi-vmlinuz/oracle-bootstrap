#!/usr/bin/env bash
# lib/oracle.sh — Oracle user/database initialization

set -euo pipefail

[[ -n "${ORACLE_DB_SOURCED:-}" ]] && return 0
ORACLE_DB_SOURCED=1

__oracle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$__oracle_lib_dir/utils.sh"
# shellcheck source=podman.sh
source "$__oracle_lib_dir/podman.sh"

readonly INIT_SQL="${__oracle_lib_dir}/../sql/init.sql"

# Check if the MCA user exists in FREEPDB1
mca_user_exists() {
    local result
    result="$(podman exec -i oracledb sqlplus -s / as sysdba <<'EOF'
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM dba_users WHERE username = 'MCA';
EXIT;
EOF
)"
    [[ "$(echo "$result" | awk '/^[[:space:]]*[0-9]+/ {print $1}' | tail -n1)" == "1" ]] || return 1
}

# Initialize database: create user, grant privileges
init_database() {
    if mca_user_exists; then
        log_ok "Database user MCA already initialized"
        return 0
    fi

    local attempts=0
    while [[ $attempts -lt 30 ]]; do
        local output
        output=$(podman exec -i "$CONTAINER_NAME" sqlplus -s / as sysdba 2>/dev/null <<'EOF'
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER mca IDENTIFIED BY mca;
GRANT CONNECT, RESOURCE TO mca;
ALTER USER mca QUOTA UNLIMITED ON USERS;
EXIT;
EOF
)
        if echo "$output" | grep -q 'ORA-01920\|ORA-01034\|ORA-12514'; then
            # User already exists or instance not ready — retry
            ((attempts++))
            sleep 2
            printf "\r[>] Waiting for database init... (%d/30)" "$attempts"
            continue
        fi
        break
    done
    printf "\n"

    # Verify the user actually exists
    if mca_user_exists; then
        log_ok "Database initialized (user MCA created)"
    else
        log_err "Failed to initialize database after 30 attempts"
        return 1
    fi
}
