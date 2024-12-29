#!/bin/bash

# Exit on error, but with cleanup
set -e
trap 'echo "An error occurred. Cleaning up..." >&2' ERR

# Configuration
REPO_URL="https://github.com/JustasZab/dotfiles"
REPO_DIR="${HOME}/.dotfiles"
CONFIG_FILES=(
    ".zshrc"
    ".tmux.conf"
    ".p10k.zsh"
)

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_dependencies() {
    local deps=(git curl zsh tmux)
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "Installing missing dependencies: ${missing_deps[*]}"
        sudo apt update
        sudo apt install -y "${missing_deps[@]}"
    fi
}

setup_repo() {
    if [ ! -d "$REPO_DIR" ]; then
        log "Cloning configuration repository..."
        git clone "$REPO_URL" "$REPO_DIR"
    else
        log "Updating configuration repository..."
        git -C "$REPO_DIR" pull
    fi
}

install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Updating Oh My Zsh..."
        ${ZSH}/tools/upgrade.sh || true
    fi
}

install_plugin() {
    local repo=$1
    local plugin_name=${2:-$(basename "$repo")}
    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"
    
    if [ ! -d "$plugin_dir" ]; then
        log "Installing ${plugin_name}..."
        git clone "https://github.com/${repo}" "$plugin_dir"
    else
        log "Updating ${plugin_name}..."
        git -C "$plugin_dir" pull
    fi
}

install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        log "Updating Powerlevel10k..."
        git -C "$p10k_dir" pull
    fi
}

setup_tmux() {
    if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
        log "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
    else
        log "Updating Tmux Plugin Manager..."
        git -C "${HOME}/.tmux/plugins/tpm" pull
    fi
}

link_config_files() {
    log "Linking configuration files..."
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "${REPO_DIR}/${file}" ]; then
            if [ -f "${HOME}/${file}" ]; then
                mv "${HOME}/${file}" "${HOME}/${file}.backup"
            fi
            ln -sf "${REPO_DIR}/${file}" "${HOME}/${file}"
        fi
    done
}

configure_shell() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        log "Changing default shell to Zsh..."
        chsh -s "$(which zsh)"
    fi
}

main() {
    log "Starting setup..."
    
    check_dependencies
    setup_repo
    install_oh_my_zsh
    
    # Set ZSH_CUSTOM after oh-my-zsh installation
    export ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"
    
    # Install/update plugins
    install_plugin "zsh-users/zsh-syntax-highlighting"
    install_plugin "zsh-users/zsh-autosuggestions"
    install_plugin "zsh-users/zsh-history-substring-search"
    install_plugin "MichaelAquilina/zsh-you-should-use" "you-should-use"
    
    install_powerlevel10k
    setup_tmux
    link_config_files
    configure_shell
    
    log "Setup complete! Please restart your terminal or run 'zsh' to start using your new setup."
}

main "$@"