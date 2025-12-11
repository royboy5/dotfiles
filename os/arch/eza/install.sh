#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up eza for Arch Linux..."

LOG_INFO "Installing eza..."
run sudo pacman -S --needed --noconfirm eza

LOG_SUCCESS "Eza setup complete! 🐙"