#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# --- Variables ---
# Configuration paths
CONFIG_SOURCE="${ROOT_DIR}/configs/nvim"
CONFIG_TARGET="$HOME/.config/nvim"

LOG_INFO "Setting up Neovim for Arch Linux..."

# 1. INSTALL NEOVIM PACKAGE
LOG_INFO "Installing neovim via Pacman..."
run sudo pacman -S --needed --noconfirm neovim

# 2. INSTALL/LINK CONFIGURATION
LOG_INFO "Linking Neovim configuration directory..."

if [[ ! -d "$CONFIG_SOURCE" ]]; then
    LOG_ERROR "Neovim config source not found: $CONFIG_SOURCE"
    LOG_WARN "Skipping configuration link."
    exit 1
fi

# Link $ROOT_DIR/configs/nvim to $HOME/.config/nvim
run link_file "$CONFIG_SOURCE" "$CONFIG_TARGET"

LOG_SUCCESS "Neovim setup complete! ✨"

LOG_INFO ""
LOG_INFO "Installation summary:"
LOG_INFO "  Binary:        /usr/bin/nvim"
LOG_INFO "  Config source: $CONFIG_SOURCE"
LOG_INFO "  Config symlink: ~/.config/nvim/ → $CONFIG_SOURCE"