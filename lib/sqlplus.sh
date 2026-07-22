#!/usr/bin/env bash
# lib/sqlplus.sh — Oracle Instant Client + SQL*Plus installer

set -euo pipefail

[[ -n "${ORACLE_SQLPLUS_SOURCED:-}" ]] && return 0
ORACLE_SQLPLUS_SOURCED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$SCRIPT_DIR/utils.sh"

readonly CACHE_DIR="${HOME}/.cache/oracle"
readonly INSTALL_DIR="${HOME}/.local/oracle"
readonly INSTANTCLIENT_BASE="instantclient-basic-linux.x64"
readonly INSTANTCLIENT_SQLPLUS="instantclient-sqlplus-linux.x64"

# Discover Instant Client version from downloaded zips
instantclient_version() {
    local base_zip sqlplus_zip
    base_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-basic*.zip' 2>/dev/null | head -n1)"
    sqlplus_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-sqlplus*.zip' 2>/dev/null | head -n1)"

    if [[ -z "$base_zip" || -z "$sqlplus_zip" ]]; then
        echo ""
        return
    fi

    # Extract version from filename like instantclient-basic-linux.x64-23.4.0.0.0.zip
    local version
    version="$(basename "$base_zip" | sed -E 's/instantclient-basic-linux\.x64-([0-9.]+)\.zip/\1/')"
    echo "$version"
}

# Check if SQL*Plus binary exists and works
sqlplus_installed() {
    if has_cmd sqlplus; then
        return 0
    fi
    if [[ -x "${INSTALL_DIR}/instantclient_*/sqlplus" ]]; then
        return 0
    fi
    return 1
}

# Install Oracle Instant Client from cached zips
install_instantclient() {
    if sqlplus_installed; then
        log_ok "SQL*Plus already installed"
        return 0
    fi

    ensure_dir "$CACHE_DIR"
    ensure_dir "$INSTALL_DIR"

    local base_zip sqlplus_zip version
    base_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-basic*.zip' 2>/dev/null | head -n1)"
    sqlplus_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-sqlplus*.zip' 2>/dev/null | head -n1)"

    if [[ -z "$base_zip" || -z "$sqlplus_zip" ]]; then
        log_warn "Oracle Instant Client ZIPs not found in $CACHE_DIR"
        log_info "Please download from: https://www.oracle.com/database/technologies/instant-client/downloads.html"
        log_info "Required files:"
        log_info "  - instantclient-basic-linux.x64-<version>.zip"
        log_info "  - instantclient-sqlplus-linux.x64-<version>.zip"
        log_info "Place them in: $CACHE_DIR"
        log_info "Then re-run ./install.sh"
        return 1
    fi

    log_info "Extracting Oracle Instant Client..."
    unzip -q -o "$base_zip" -d "$INSTALL_DIR"
    unzip -q -o "$sqlplus_zip" -d "$INSTALL_DIR"
    log_ok "Oracle Instant Client extracted"

    # Set up environment via shell integration (handled by shell.sh)
    : # noop, shell.sh does the PATH/LD_LIBRARY_PATH setup
}

# Return the instantclient directory path for shell integration
instantclient_dir() {
    local ic_dir
    ic_dir="$(find "$INSTALL_DIR" -maxdepth 1 -type d -name 'instantclient_*' 2>/dev/null | head -n1)"
    echo "$ic_dir"
}
