#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up fzf for Arch Linux..."

LOG_INFO "Installing fzf..."
run sudo pacman -S --needed --noconfirm fzf

LOG_SUCCESS "Fzf setup complete! 🐙"