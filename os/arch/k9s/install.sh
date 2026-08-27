#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up k9s for Arch Linux..."

LOG_INFO "Installing k9s..."
run sudo pacman -S --needed --noconfirm k9s

LOG_SUCCESS "K9s setup complete! 🐙"