#!/usr/bin/env bash
# install.sh — Oracle Database Development Bootstrapper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/distro.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/podman.sh"
source "$SCRIPT_DIR/lib/sqlplus.sh"
source "$SCRIPT_DIR/lib/oracle.sh"
source "$SCRIPT_DIR/lib/shell.sh"

log_info "=============================================="
log_info "  Oracle Database Development Bootstrapper"
log_info "=============================================="
log_info ""

# --- Detect distribution ---
DISTRO="$(detect_distro)"
log_info "Detected distribution: $DISTRO"

if [[ "$DISTRO" == "unknown" ]]; then
    log_err "Unsupported or unknown Linux distribution."
    log_err "Supported: Fedora, Ubuntu, Linux Mint, Debian, Kali Linux, Arch, openSUSE"
    exit 1
fi

# --- Install base dependencies ---
log_info ""
log_info "Installing base dependencies (sudo may be required)..."
install_base_deps

# --- Install Oracle Instant Client ---
log_info ""
log_info "Installing Oracle Instant Client..."
install_instantclient

# --- Pull Oracle image ---
log_info ""
log_info "Pulling Oracle Database container image..."
pull_oracle_image

# --- Create/start container ---
log_info ""
log_info "Setting up Oracle container..."
start_container

# --- Wait for Oracle ---
wait_for_oracle

# --- Initialize database ---
log_info ""
log_info "Initializing database..."
init_database

# --- Install commands ---
log_info ""
log_info "Installing shell commands..."
install_commands

# --- Setup Oracle environment ---
log_info ""
log_info "Configuring Oracle environment..."
setup_oracle_env

# --- Done ---
log_info ""
log_info "=============================================="
log_ok  "Installation complete!"
log_info "=============================================="
log_info ""
log_info "Commands installed:"
log_info "  connect-db    — Start container, wait, connect via SQL*Plus"
log_info "  sqlplus-now   — Connect instantly (container must be running)"
log_info ""
print_reload_hint
