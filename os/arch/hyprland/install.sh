#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up hyprland for Arch Linux..."

LOG_INFO "Installing hyprland..."
run sudo pacman -S --needed --noconfirm hyprland

LOG_SUCCESS "Hyprland setup complete! 🐙"