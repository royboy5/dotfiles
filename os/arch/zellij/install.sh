#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up zellij for Arch Linux..."

LOG_INFO "Installing zellij..."
run sudo pacman -S --needed --noconfirm zellij 

LOG_SUCCESS "Eza setup complete! 🐙"
