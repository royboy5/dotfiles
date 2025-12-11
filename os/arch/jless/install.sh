#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

LOG_INFO "Setting up jless for Arch Linux..."

LOG_INFO "Installing jless..."
run sudo pacman -S --needed --noconfirm jless

LOG_SUCCESS "Jless setup complete! 🐙"