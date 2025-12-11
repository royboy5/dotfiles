#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up fd for Arch Linux..."

LOG_INFO "Installing go..."
run sudo pacman -S --needed --noconfirm go

LOG_SUCCESS "Go setup complete! 🐙"