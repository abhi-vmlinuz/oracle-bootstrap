#!/usr/bin/env bash
# lib/sqlplus.sh — Oracle Instant Client + SQL*Plus installer

set -euo pipefail

[[ -n "${ORACLE_SQLPLUS_SOURCED:-}" ]] && return 0
ORACLE_SQLPLUS_SOURCED=1

__oracle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$__oracle_lib_dir/utils.sh"

readonly CACHE_DIR="${HOME}/.cache/oracle"
readonly INSTALL_DIR="${HOME}/.local/oracle"
readonly ORACLE_DL_PAGE="https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html"

# Configurable Oracle Instant Client version
# Override before sourcing: ORACLE_IC_VERSION=23.4.0.24.05
readonly ORACLE_IC_VERSION="${ORACLE_IC_VERSION:-23.4.0.24.05}"

# Direct download URL (Oracle may require authentication; this is a best-effort attempt)
ic_download_url() {
    local filename="$1"
    # Oracle URL ID = (major*10 + minor) * 10000, e.g. 23.4.0.0.0 -> 234*10000 = 2340000
    local major minor url_id
    major="${ORACLE_IC_VERSION%%.*}"
    minor="${ORACLE_IC_VERSION#${major}.}"
    minor="${minor%%.*}"
    url_id=$(( (major * 10 + minor) * 10000 ))
    echo "https://download.oracle.com/otn_software/linux/instantclient/${url_id}/${filename}"
}

# Expected filenames
ic_base_filename() { echo "instantclient-basic-linux.x64-${ORACLE_IC_VERSION}.zip"; }
ic_sqlplus_filename() { echo "instantclient-sqlplus-linux.x64-${ORACLE_IC_VERSION}.zip"; }

# Check if SQL*Plus binary exists and works
sqlplus_installed() {
    if has_cmd sqlplus; then
        return 0
    fi
    local ic_dir
    ic_dir="$(instantclient_dir)"
    if [[ -n "$ic_dir" && -x "${ic_dir}/sqlplus" ]]; then
        return 0
    fi
    return 1
}

# Return the instantclient directory path for shell integration
instantclient_dir() {
    local ic_dir
    ic_dir="$(find "$INSTALL_DIR" -maxdepth 1 -type d -name 'instantclient_*' 2>/dev/null | head -n1)"
    echo "$ic_dir"
}

# Try to download a single file from Oracle
download_oracle_file() {
    local filename="$1"
    local outfile="${CACHE_DIR}/${filename}"
    local url
    url="$(ic_download_url "$filename")"

    if [[ -f "$outfile" ]]; then
        log_ok "$filename already cached"
        return 0
    fi

    log_info "Attempting to download $filename..."
    log_info "URL: $url"

    if has_cmd curl; then
        if curl -fsSL \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
            --cookie "oraclelicense=accept-securebackup-cookie" \
            -o "$outfile" "$url"; then
            log_ok "$filename downloaded"
            return 0
        fi
    elif has_cmd wget; then
        if wget -q \
            --user-agent="Mozilla/5.0 (X11; Linux x86_64)" \
            --header="Cookie: oraclelicense=accept-securebackup-cookie" \
            -O "$outfile" "$url"; then
            log_ok "$filename downloaded"
            return 0
        fi
    fi

    log_warn "Auto-download failed for $filename"
    return 1
}

# Print manual download instructions
print_manual_dl_instructions() {
    log_warn ""
    log_warn "Could not auto-download Oracle Instant Client."
    log_warn ""
    log_warn "Download these two files from:"
    log_warn "  ${ORACLE_DL_PAGE}"
    log_warn ""
    log_warn "Required files:"
    log_warn "  1. $(ic_base_filename)"
    log_warn "  2. $(ic_sqlplus_filename)"
    log_warn ""
    log_warn "Then either:"
    log_warn "  A) Put them in this folder: ${SCRIPT_DIR}/"
    log_warn "     (just drop them next to install.sh and re-run)"
    log_warn ""
    log_warn "  B) Put them in: ${CACHE_DIR}/"
    log_warn "     (the script will find them there)"
    log_warn ""
    log_warn "Then re-run: ./install.sh"
    log_warn ""
}

# Download both Instant Client ZIPs
download_instantclient() {
    ensure_dir "$CACHE_DIR"

    local base_filename sqlplus_filename
    base_filename="$(ic_base_filename)"
    sqlplus_filename="$(ic_sqlplus_filename)"

    local failed=0

    if ! download_oracle_file "$base_filename"; then
        ((failed++)) || true
    fi

    if ! download_oracle_file "$sqlplus_filename"; then
        ((failed++)) || true
    fi

    if [[ $failed -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Install Oracle Instant Client from cached zips
install_instantclient() {
    if sqlplus_installed; then
        log_ok "SQL*Plus already installed"
        return 0
    fi

    ensure_dir "$CACHE_DIR"
    ensure_dir "$INSTALL_DIR"

    local base_zip sqlplus_zip
    base_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-basic*.zip' 2>/dev/null | head -n1)"
    sqlplus_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-sqlplus*.zip' 2>/dev/null | head -n1)"

    # If zips missing, try to download them
    if [[ -z "$base_zip" || -z "$sqlplus_zip" ]]; then
        log_info "Oracle Instant Client ZIPs not found in $CACHE_DIR, attempting download..."
        if ! download_instantclient; then
            log_warn "Auto-download failed. Checking for ZIPs in install directory..."
        fi

        # Look for ZIPs in the repo directory (where install.sh lives)
        # This is the "just drop them here" convenience path
        local repo_base repo_sqlplus
        repo_base="$(find "$SCRIPT_DIR" -maxdepth 1 -name 'instantclient-basic*.zip' 2>/dev/null | head -n1)"
        repo_sqlplus="$(find "$SCRIPT_DIR" -maxdepth 1 -name 'instantclient-sqlplus*.zip' 2>/dev/null | head -n1)"

        if [[ -n "$repo_base" && -n "$repo_sqlplus" ]]; then
            log_ok "Found Oracle ZIPs in install directory"
            log_info "Copying to $CACHE_DIR..."
            cp -n "$repo_base" "$CACHE_DIR/"
            cp -n "$repo_sqlplus" "$CACHE_DIR/"
            log_ok "ZIPs copied"
        fi

        # Re-scan after download/copy
        base_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-basic*.zip' 2>/dev/null | head -n1)"
        sqlplus_zip="$(find "$CACHE_DIR" -maxdepth 1 -name 'instantclient-sqlplus*.zip' 2>/dev/null | head -n1)"

        # If still missing, show super simple instructions
        if [[ -z "$base_zip" || -z "$sqlplus_zip" ]]; then
            print_manual_dl_instructions
            return 1
        fi
    fi

    if [[ -z "$base_zip" || -z "$sqlplus_zip" ]]; then
        log_err "Oracle Instant Client ZIPs still not found after download attempt"
        print_manual_dl_instructions
        return 1
    fi

    log_info "Extracting Oracle Instant Client..."
    unzip -q -o "$base_zip" -d "$INSTALL_DIR"
    unzip -q -o "$sqlplus_zip" -d "$INSTALL_DIR"
    log_ok "Oracle Instant Client extracted"

    # Ensure binaries are executable (ZIP extraction may not preserve perms)
    local ic_dir
    ic_dir="$(instantclient_dir)"
    if [[ -d "$ic_dir" ]]; then
        chmod +x "${ic_dir}"/* 2>/dev/null || true
    fi

    # Verify sqlplus binary exists
    if [[ -z "$ic_dir" || ! -x "${ic_dir}/sqlplus" ]]; then
        log_err "SQL*Plus binary not found after extraction. Something went wrong."
        return 1
    fi

    log_ok "SQL*Plus is ready"
}
