#!/usr/bin/env bash
# lib/oracle.sh — Oracle user/database initialization

set -euo pipefail

[[ -n "${ORACLE_DB_SOURCED:-}" ]] && return 0
ORACLE_DB_SOURCED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"
# shellcheck source=podman.sh
source "$SCRIPT_DIR/podman.sh"

readonly INIT_SQL="${SCRIPT_DIR}/../sql/init.sql"

# Check if the MCA user exists
mca_user_exists() {
    local result
    result="$(podman exec -i oracledb sqlplus -s / as sysdba <<'EOF'
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM dba_users WHERE username = 'MCA';
EXIT;
EOF
)"
    [[ "$(echo "$result" | tr -d '[:space:]')" == "1" ]]
}

# Initialize database: create user, grant privileges
init_database() {
    if mca_user_exists; then
        log_ok "Database user MCA already initialized"
        return 0
    fi

    log_info "Initializing database (creating MCA user)..."

    # Run init SQL
    podman exec -i oracledb sqlplus -s / as sysdba <<'EOF'
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER mca IDENTIFIED BY mca;
GRANT CONNECT, RESOURCE TO mca;
ALTER USER mca QUOTA UNLIMITED ON USERS;
EXIT;
EOF

    log_ok "Database initialized (user MCA created)"
}
