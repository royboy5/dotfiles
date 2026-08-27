#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up starship for Arch Linux..."

LOG_INFO "Installing starship..."
run sudo pacman -S --needed --noconfirm starship

# INK CONFIGURATION
STARSHIP_CONFIG_SOURCE="${ROOT_DIR}/configs/starship/"
StARSHIP_CONFIG_TARGET="$HOME/.config/starship"

if [[ -f "$STARSHIP_CONFIG_SOURCE" ]]; then
    LOG_INFO "Linking Starship configuration..."
    run link_file "$STARSHIP_CONFIG_SOURCE" "$StARSHIP_CONFIG_TARGET"
else
    LOG_WARN "Skipping Starship configuration link: Source file not found."
fi

LOG_SUCCESS "Starship setup complete! 🐙"