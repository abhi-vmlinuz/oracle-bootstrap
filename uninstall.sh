#!/usr/bin/env bash
# uninstall.sh — Remove Oracle Bootstrap configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

CONTAINER_NAME="oracledb"
VOLUME_NAME="oracledb_data"
BIN_DIR="${HOME}/.local/bin"

echo "Oracle Bootstrap Uninstaller"
echo ""

# Remove container
if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    log_info "Removing Oracle container..."
    podman rm -f "$CONTAINER_NAME"
    log_ok "Container removed"
else
    log_ok "No Oracle container found"
fi

# Remove volume
if podman volume exists "$VOLUME_NAME" 2>/dev/null; then
    log_info "Removing Oracle data volume..."
    podman volume rm "$VOLUME_NAME"
    log_ok "Volume removed"
else
    log_ok "No Oracle volume found"
fi

# Remove commands
for cmd in connect-db sqlplus-now; do
    if [[ -f "${BIN_DIR}/${cmd}" ]]; then
        rm -f "${BIN_DIR}/${cmd}"
        log_ok "Removed ${cmd}"
    fi
done

# Remove shell integration files
for f in \
    "${HOME}/.bashrc.d/oracle-bootstrap.sh" \
    "${HOME}/.zshrc.d/oracle-bootstrap.zsh" \
    "${HOME}/.config/fish/conf.d/oracle-bootstrap.fish" \
    "${HOME}/.config/fish/conf.d/oracle-bootstrap-env.fish"; do
    if [[ -f "$f" ]]; then
        rm -f "$f"
        log_ok "Removed $(basename "$f")"
    fi
done

# Optionally remove Instant Client
read -rp "Remove Oracle Instant Client from ~/.local/oracle? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -rf "${HOME}/.local/oracle"
    log_ok "Removed ~/.local/oracle"
fi

# Optionally remove cached downloads
read -rp "Remove cached downloads from ~/.cache/oracle? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -rf "${HOME}/.cache/oracle"
    log_ok "Removed ~/.cache/oracle"
fi

echo ""
log_ok "Uninstall complete."
log_info "Note: PATH entries in ~/.bashrc and ~/.zshrc were not removed."
log_info "      You may manually edit those files if desired."
