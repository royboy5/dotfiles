#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up reflector for Arch Linux..."

LOG_INFO "Installing reflector..."
run sudo pacman -S --needed --noconfirm reflector

LOG_SUCCESS "Reflector setup complete! 🐙"