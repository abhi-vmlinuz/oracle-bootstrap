#!/usr/bin/env bash
# lib/distro.sh — Linux distribution detection

set -euo pipefail

[[ -n "${ORACLE_DISTRO_SOURCED:-}" ]] && return 0
ORACLE_DISTRO_SOURCED=1

# Detect distribution ID from /etc/os-release
# Returns: fedora, ubuntu, debian, linuxmint, kali, arch, opensuse, unknown
detect_distro() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        case "${ID:-unknown}" in
            fedora) echo "fedora" ;;
            ubuntu) echo "ubuntu" ;;
            debian) echo "debian" ;;
            linuxmint) echo "linuxmint" ;;
            kali) echo "kali" ;;
            arch|manjaro) echo "arch" ;;
            opensuse*|suse*) echo "opensuse" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

# Detect package manager based on distro detect_distro() {
detect_pkg_manager() {
    local distro
    distro="$(detect_distro)"
    case "$distro" in
        fedora) echo "dnf" ;;
        ubuntu|debian|linuxmint|kali) echo "apt" ;;
        arch) echo "pacman" ;;
        opensuse) echo "zypper" ;;
        *) echo "unknown" ;;
    esac
}
