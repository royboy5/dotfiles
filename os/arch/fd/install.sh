#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up fd for Arch Linux..."

LOG_INFO "Installing fd..."
run sudo pacman -S --needed --noconfirm fd

LOG_SUCCESS "fd setup complete! 🐙"