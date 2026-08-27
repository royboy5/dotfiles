#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up ripgrep for Arch Linux..."

LOG_INFO "Installing ripgrep..."
run sudo pacman -S --needed --noconfirm ripgrep

LOG_SUCCESS "Ripgrep setup complete! 🐙"