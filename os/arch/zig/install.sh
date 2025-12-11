#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up zig for Arch Linux..."

LOG_INFO "Installing zig..."
run sudo pacman -S --needed --noconfirm zig

LOG_SUCCESS "Zig setup complete! 🐙"