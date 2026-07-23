#!/usr/bin/env bash
# lib/shell.sh — shell integration for Bash, Zsh, Fish

set -euo pipefail

[[ -n "${ORACLE_SHELL_SOURCED:-}" ]] && return 0
ORACLE_SHELL_SOURCED=1

__oracle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "$__oracle_lib_dir/utils.sh"
# shellcheck source=sqlplus.sh
source "$__oracle_lib_dir/sqlplus.sh"

readonly SCRIPTS_DIR="${__oracle_lib_dir}/../scripts"

# Install commands into ~/.local/bin
install_commands() {
    local bin_dir="${HOME}/.local/bin"
    ensure_dir "$bin_dir"

    for script in connect-db sqlplus-now; do
        local src="${SCRIPTS_DIR}/${script}"
        local dest="${bin_dir}/${script}"
        if [[ -f "$src" ]]; then
            cp -f "$src" "$dest"
            chmod +x "$dest"
            log_ok "Installed ${script} → ${dest}"
        else
            log_err "Missing script: $src"
            return 1
        fi
    done

    # Ensure ~/.local/bin is on PATH
    ensure_path_entry "${HOME}/.bashrc" "$bin_dir"
    ensure_path_entry "${HOME}/.zshrc" "$bin_dir"
    ensure_fish_path "$bin_dir"
}

# Add PATH entry to rc file if missing
ensure_path_entry() {
    local rcfile="$1"
    local bindir="$2"

    if [[ ! -f "$rcfile" ]]; then
        return 0
    fi

    local path_line
    path_line="export PATH=\"${bindir}:\$PATH\""

    if ! grep -qxF "$path_line" "$rcfile" 2>/dev/null; then
        # Also check for any other mention of this bindir
        if ! grep -q "$bindir" "$rcfile" 2>/dev/null; then
            echo "" >> "$rcfile"
            echo "# Oracle Bootstrap PATH" >> "$rcfile"
            echo "$path_line" >> "$rcfile"
            log_ok "Added ${bindir} to PATH in ${rcfile}"
        fi
    fi
}

# Add path for Fish shell
ensure_fish_path() {
    local bindir="$1"
    local fish_conf_dir="${HOME}/.config/fish/conf.d"
    local fish_conf="${fish_conf_dir}/oracle-bootstrap.fish"

    if ! has_cmd fish 2>/dev/null && [[ ! -d "${HOME}/.config/fish" ]]; then
        return 0
    fi

    ensure_dir "$fish_conf_dir"

    local path_line
    path_line="fish_add_path ${bindir}"

    if [[ ! -f "$fish_conf" ]] || ! grep -qxF "$path_line" "$fish_conf" 2>/dev/null; then
        echo "# Oracle Bootstrap PATH" > "$fish_conf"
        echo "$path_line" >> "$fish_conf"
        log_ok "Added ${bindir} to Fish PATH in ${fish_conf}"
    fi
}

# Setup Oracle environment variables (LD_LIBRARY_PATH, ORACLE_HOME)
setup_oracle_env() {
    local ic_dir
    ic_dir="$(instantclient_dir)"

    if [[ -z "$ic_dir" || ! -d "$ic_dir" ]]; then
        log_warn "Instant Client directory not found, skipping environment setup"
        return 0
    fi

    # Bash / Zsh drop-in configs
    local bash_d="${HOME}/.bashrc.d"
    local zsh_d="${HOME}/.zshrc.d"

    ensure_dir "$bash_d"
    ensure_dir "$zsh_d"

    local env_bash="${bash_d}/oracle-bootstrap.sh"
    local env_zsh="${zsh_d}/oracle-bootstrap.zsh"

    cat > "$env_bash" <<EOF
# Oracle Instant Client environment
export ORACLE_HOME="${ic_dir}"
export PATH="${ic_dir}:\${PATH}"
export LD_LIBRARY_PATH="${ic_dir}:\${LD_LIBRARY_PATH:-}"
EOF

    cp -f "$env_bash" "$env_zsh"
    log_ok "Oracle environment configured for Bash/Zsh"

    # Ensure rc files source drop-in dirs
    ensure_source_dropin "${HOME}/.bashrc" "$bash_d"
    ensure_source_dropin "${HOME}/.zshrc" "$zsh_d"

    # Fish
    local fish_conf_dir="${HOME}/.config/fish/conf.d"
    local fish_env="${fish_conf_dir}/oracle-bootstrap-env.fish"
    ensure_dir "$fish_conf_dir"

    cat > "$fish_env" <<EOF
# Oracle Instant Client environment
set -gx ORACLE_HOME ${ic_dir}
set -gx LD_LIBRARY_PATH ${ic_dir} \$LD_LIBRARY_PATH
fish_add_path ${ic_dir}
EOF
    log_ok "Oracle environment configured for Fish"
}

# Ensure an rc file sources all files in a drop-in directory
ensure_source_dropin() {
    local rcfile="$1"
    local dropin_dir="$2"

    if [[ ! -f "$rcfile" ]]; then
        return 0
    fi

    local source_line
    source_line="for f in ${dropin_dir}/*; do [[ -f \"\$f\" && -r \"\$f\" ]] && source \"\$f\"; done"

    # Check if dropin dir is already sourced
    if ! grep -q "$dropin_dir" "$rcfile" 2>/dev/null; then
        echo "" >> "$rcfile"
        echo "# Source drop-in configurations" >> "$rcfile"
        echo "$source_line" >> "$rcfile"
        log_ok "Added drop-in source to ${rcfile}"
    fi
}

# Print shell reload instructions
print_reload_hint() {
    log_info ""
    log_info "To use the new commands, reload your shell or run:"
    log_info "  source ~/.bashrc   # for Bash"
    log_info "  source ~/.zshrc    # for Zsh"
    log_info "  Or open a new terminal window"
}
