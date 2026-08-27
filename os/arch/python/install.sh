#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# --- Configuration Variables ---
# Packages required to download and execute the uv installer
CORE_TOOLS=(
    "curl"
    "unzip"
)

# Tools to install globally using 'uv tool install'
GLOBAL_TOOLS=(
    "jupyter-core"
    "notebook"
    "ruff"
    "ipython"
)

# The default path where the uv installer places the binary
UV_BIN_PATH="$HOME/.cargo/bin"

LOG_INFO "Setting up Python environment using 'uv' for Arch Linux..."

# 1. INSTALL CORE DEPENDENCIES (curl and unzip)
LOG_INFO "Ensuring curl and unzip are installed for uv installation..."
run sudo pacman -S --needed --noconfirm "${CORE_TOOLS[@]}"

# 2. INSTALL UV ITSELF
LOG_INFO "Installing uv package manager via astral.sh script..."
if [[ ! -f "$UV_BIN_PATH/uv" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
        LOG_INFO "[dry-run] curl -LsSf https://astral.sh/uv/install.sh | sh"
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    LOG_SUCCESS "uv installed successfully."
else
    LOG_SUCCESS "uv is already installed."
fi

# 3. ADD UV BINARY PATH TO CURRENT SESSION
export PATH="$UV_BIN_PATH:$PATH"
LOG_INFO "Added $UV_BIN_PATH to PATH for this script execution."

# 4. INSTALL LATEST PYTHON VERSION
LOG_INFO "Installing the latest stable Python version using uv python install..."
run uv python install

# 5. PIN DEFAULT VERSION
LOG_INFO "The latest version installed by uv is automatically set as the global default."

# 6. INSTALL GLOBAL TOOLS
LOG_INFO "Installing global Python tools: ${GLOBAL_TOOLS[*]} using uv tool install..."

# FIX: Loop over the array and run 'uv tool install' for each item separately
for tool in "${GLOBAL_TOOLS[@]}"; do
    LOG_INFO "  -> Installing $tool..."
    run uv tool install "$tool"
done

# 7. Final Verification and Reminder
LOG_INFO "Verification and reminders:"
LOG_INFO "  uv and related tools are installed in $UV_BIN_PATH."
LOG_WARN "  Ensure $UV_BIN_PATH is permanently added to your shell's PATH."

LOG_SUCCESS "Python environment setup complete! 🐍"