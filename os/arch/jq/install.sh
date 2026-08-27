#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up jq for Arch Linux..."

LOG_INFO "Installing jq..."
run sudo pacman -S --needed --noconfirm jq

LOG_SUCCESS "Jq setup complete! 🐙"