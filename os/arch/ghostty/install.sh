#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up ghostty for Arch Linux..."

LOG_INFO "Installing ghostty..."
run sudo pacman -S --needed --noconfirm ghostty

LOG_SUCCESS "Ghostty setup complete! 🐙"