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

# Check if a package is installed
is_pkg_installed() {
    local pkg="$1"
    local pkg_manager="$2"
    case "$pkg_manager" in
        apt)
            if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed"; then
                return 0
            fi
            # Handle libaio virtual package on trixie
            if [[ "$pkg" == libaio1 ]] && dpkg-query -W -f='${Status}' libaio1t64 2>/dev/null | grep -q "^install ok installed"; then
                return 0
            fi
            return 1
            ;;
        dnf|rpm)
            rpm -q "$pkg" &>/dev/null
            ;;
        pacman)
            pacman -Q "$pkg" &>/dev/null
            ;;
        zypper)
            rpm -q "$pkg" &>/dev/null
            ;;
        *)
            has_cmd "$pkg" 2>/dev/null
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
        if is_pkg_installed "$bin" "$pkg_manager"; then
            log_ok "$bin already installed"
            continue
        fi

        log_info "Installing $bin..."
        case "$pkg_manager" in
            dnf)
                if sudo dnf install -y "$bin"; then
                    log_ok "$bin installed"
                else
                    log_err "Failed to install $bin"
                    return 1
                fi
                ;;
            apt)
                sudo -v || true
                sudo apt-get update
                if sudo apt-get install -y "$bin"; then
                    log_ok "$bin installed"
                elif [[ "$bin" == libaio* ]] && apt-cache show libaio1t64 &>/dev/null; then
                    log_warn "$bin not found in apt cache, trying libaio1t64..."
                    sudo apt-get install -y libaio1t64
                    log_ok "libaio1t64 installed"
                else
                    log_err "Failed to install $bin"
                    return 1
                fi
                ;;
            pacman)
                if sudo pacman -S --noconfirm "$bin"; then
                    log_ok "$bin installed"
                else
                    log_err "Failed to install $bin"
                    return 1
                fi
                ;;
            zypper)
                if sudo zypper install -y "$bin"; then
                    log_ok "$bin installed"
                else
                    log_err "Failed to install $bin"
                    return 1
                fi
                ;;
            *)
                log_err "Unknown package manager. Please install $bin manually."
                return 1
                ;;
        esac
    done
}

# Install all base dependencies
install_base_deps() {
    local deps=(curl wget unzip tar gzip rlwrap podman libaio)
    for dep in "${deps[@]}"; do
        install_pkg "$dep"
    done
}
