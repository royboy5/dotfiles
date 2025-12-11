#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up tree for Arch Linux..."

LOG_INFO "Installing tree..."
run sudo pacman -S --needed --noconfirm tree

LOG_SUCCESS "Tree setup complete! 🐙"