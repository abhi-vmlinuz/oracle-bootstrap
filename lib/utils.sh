#!/usr/bin/env bash
# lib/utils.sh — logging and utility functions

set -euo pipefail

[[ -n "${ORACLE_UTILS_SOURCED:-}" ]] && return 0
ORACLE_UTILS_SOURCED=1

# Colors
readonly C_GREEN='\033[0;32m'
readonly C_RED='\033[0;31m'
readonly C_YELLOW='\033[1;33m'
readonly C_RESET='\033[0m'

log_ok() {
    printf "${C_GREEN}[✓]${C_RESET} %s\n" "$1"
}

log_warn() {
    printf "${C_YELLOW}[!]${C_RESET} %s\n" "$1"
}

log_err() {
    printf "${C_RED}[✗]${C_RESET} %s\n" "$1" >&2
}

log_info() {
    printf "[>] %s\n" "$1"
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Ensure a directory exists
ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
    fi
}

# Append a line to a file only if not already present
append_if_missing() {
    local file="$1"
    local line="$2"
    ensure_dir "$(dirname "$file")"
    if [[ ! -f "$file" ]] || ! grep -qxF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
    fi
}
