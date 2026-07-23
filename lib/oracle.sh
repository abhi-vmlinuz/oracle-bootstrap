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
    if result="$(podman exec -i "$CONTAINER_NAME" sqlplus -s / as sysdba 2>&1 <<'EOF'
WHENEVER SQLERROR EXIT 1;
WHENEVER OSERROR EXIT 1;
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM dba_users WHERE username = 'MCA';
EXIT;
EOF
)"; then
        [[ "$(echo "$result" | tr -d '[:space:]')" == "1" ]]
    else
        return 1
    fi
}

# Initialize database: create user, grant privileges
init_database() {
    if mca_user_exists; then
        log_ok "Database user MCA already initialized"
        return 0
    fi

    local attempts=0
    local max_attempts=30
    local output

    while [[ $attempts -lt $max_attempts ]]; do
        if output="$(podman exec -i "$CONTAINER_NAME" sqlplus -s / as sysdba 2>&1 <<'EOF'
WHENEVER SQLERROR EXIT 1;
WHENEVER OSERROR EXIT 1;
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER mca IDENTIFIED BY mca;
GRANT CONNECT, RESOURCE TO mca;
GRANT CREATE VIEW, CREATE SYNONYM TO mca;
ALTER USER mca QUOTA UNLIMITED ON USERS;
EXIT;
EOF
)"; then
            if mca_user_exists; then
                log_ok "Database initialized (user MCA created)"
                return 0
            fi
        else
            if mca_user_exists; then
                log_ok "Database initialized (user MCA created)"
                return 0
            fi
            if echo "$output" | grep -q 'ORA-01920'; then
                log_ok "Database user MCA already exists"
                return 0
            fi
        fi

        ((attempts++))
        sleep 2
        printf "\r[>] Waiting for database init... (%d/%d)" "$attempts" "$max_attempts"
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
