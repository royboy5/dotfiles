#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up httpie for Arch Linux..."

LOG_INFO "Installing httpie..."
run sudo pacman -S --needed --noconfirm httpie

LOG_SUCCESS "Httpie setup complete! 🐙"