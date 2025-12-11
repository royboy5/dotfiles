#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up xclip for Arch Linux..."

LOG_INFO "Installing xclip..."
run sudo pacman -S --needed --noconfirm xclip

LOG_SUCCESS "Xclip setup complete! 🐙"