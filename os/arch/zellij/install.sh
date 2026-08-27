#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# Configuration Paths
CONFIG_SOURCE="${ROOT_DIR}/configs/zellij"
CONFIG_TARGET="$HOME/.config/zellij"

LOG_INFO "Setting up Zellij for Arch Linux..."

# 1. INSTALL ZELLIJ
LOG_INFO "Installing zellij..."
run sudo pacman -S --needed --noconfirm zellij

# 2. LINK CONFIGURATION
LOG_INFO "Linking zellij configuration..."
run link_file "$CONFIG_SOURCE" "$CONFIG_TARGET"

LOG_SUCCESS "Zellij setup complete! 🚀"
LOG_INFO ""
LOG_INFO "Installation summary:"
LOG_INFO "  Config source:   $CONFIG_SOURCE"
LOG_INFO "  Config symlink:  ~/.config/zellij/ → $CONFIG_SOURCE"
