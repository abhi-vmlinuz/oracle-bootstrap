#!/usr/bin/env bash
# lib/packages.sh — package manager operations

set -euo pipefail

[[ -n "${ORACLE_PACKAGES_SOURCED:-}" ]] && return 0
ORACLE_PACKAGES_SOURCED=1

__oracle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$__oracle_lib_dir/utils.sh"
# shellcheck source=distro.sh
source "$__oracle_lib_dir/distro.sh"

# Map of package names per distro
pkg_map() {
    local pkg="$1"
    local distro
    distro="$(detect_distro)"
    case "$pkg" in
        podman)
            case "$distro" in
                arch) echo "podman podman-docker" ;;
                *) echo "podman" ;;
            esac
            ;;
        rlwrap)
            echo "rlwrap"
            ;;
        curl)
            echo "curl"
            ;;
        wget)
            echo "wget"
            ;;
        unzip)
            echo "unzip"
            ;;
        tar)
            echo "tar"
            ;;
        gzip)
            echo "gzip"
            ;;
        libaio)
            case "$distro" in
                fedora) echo "libaio" ;;
                ubuntu|debian|linuxmint|kali) echo "libaio1" ;;
                arch) echo "libaio" ;;
                opensuse) echo "libaio1" ;;
                *) echo "libaio1" ;;
            esac
            ;;
        *)
            echo "$pkg"
            ;;
    esac
}

# Install a package if not already present
install_pkg() {
    local pkg_raw="$1"
    local pkg_mapped
    pkg_mapped="$(pkg_map "$pkg_raw")"
    local pkg_manager
    pkg_manager="$(detect_pkg_manager)"

    for bin in $pkg_mapped; do
        if has_cmd "$bin" 2>/dev/null || dpkg -l "$bin" &>/dev/null || rpm -q "$bin" &>/dev/null; then
            log_ok "$bin already installed"
            continue
        fi

        log_info "Installing $bin..."
        case "$pkg_manager" in
            dnf)
                sudo dnf install -y "$bin"
                ;;
            apt)
                sudo -v || true
                sudo apt-get update
                sudo apt-get install -y "$bin"
                ;;
            pacman)
                sudo pacman -S --noconfirm "$bin"
                ;;
            zypper)
                sudo zypper install -y "$bin"
                ;;
            *)
                log_err "Unknown package manager. Please install $bin manually."
                return 1
                ;;
        esac
        log_ok "$bin installed"
    done
}

# Install all base dependencies
install_base_deps() {
    local deps=(curl wget unzip tar gzip rlwrap podman libaio)
    for dep in "${deps[@]}"; do
        install_pkg "$dep"
    done
}
