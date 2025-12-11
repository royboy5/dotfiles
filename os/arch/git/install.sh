#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up Git for Arch Linux..."

# 1. INSTALL GIT
LOG_INFO "Installing git package..."
run sudo pacman -S --needed --noconfirm git

# 2. LINK CONFIGURATION
GIT_CONFIG_SOURCE="${ROOT_DIR}/configs/git/.gitconfig"
GIT_CONFIG_TARGET="$HOME/.gitconfig"

if [[ -f "$GIT_CONFIG_SOURCE" ]]; then
    LOG_INFO "Linking Git configuration..."
    run link_file "$GIT_CONFIG_SOURCE" "$GIT_CONFIG_TARGET"
else
    LOG_WARN "Skipping Git configuration link: Source file not found."
fi

LOG_SUCCESS "Git setup complete! 🐙"