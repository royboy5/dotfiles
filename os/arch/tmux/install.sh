#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# --- Variables ---
TMUX_PACKAGE="tmux"
# Path where TPM will be cloned (standard location)
TPM_DIR="$HOME/.tmux/plugins/tpm"

# Configuration paths
CONFIG_SOURCE="${ROOT_DIR}/configs/tmux/.tmux.conf"
CONFIG_TARGET="$HOME/.tmux.conf"

LOG_INFO "Setting up Tmux and Tmux Plugin Manager (TPM) for Arch Linux..."

# 1. INSTALL TMUX PACKAGE AND GIT DEPENDENCY
LOG_INFO "Installing ${TMUX_PACKAGE} via Pacman..."
# Tmux needs git to manage TPM plugins, so we explicitly install it here if it wasn't already.
run sudo pacman -S --needed --noconfirm "${TMUX_PACKAGE}" git

# 2. LINK TMUX CONFIGURATION
LOG_INFO "Linking Tmux configuration file..."

if [[ ! -f "$CONFIG_SOURCE" ]]; then
    LOG_ERROR "Tmux config source not found: $CONFIG_SOURCE"
    LOG_WARN "Skipping configuration link. You must manually create .tmux.conf for TPM to work."
    # We exit here because TPM installation will fail if there is no config file to load it.
    exit 1
fi

# The link_file helper handles creation of parent directory, checking for existing links, and moving existing files.
# It links $ROOT_DIR/configs/tmux/.tmux.conf to $HOME/.tmux.conf
run link_file "$CONFIG_SOURCE" "$CONFIG_TARGET"

LOG_SUCCESS "Tmux config linked: ~/.tmux.conf -> $CONFIG_SOURCE"

# 3. INSTALL/UPDATE TPM (Tmux Plugin Manager)
LOG_INFO "Installing/Updating Tmux Plugin Manager (TPM)..."

if [[ ! -d "$TPM_DIR" ]]; then
    LOG_INFO "Cloning TPM repository to $TPM_DIR..."
    run git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    LOG_INFO "TPM already exists. Pulling latest changes..."
    if [[ "${DRY_RUN}" == true ]]; then
        LOG_INFO "[dry-run] cd '$TPM_DIR' && git pull"
    else
        # Navigate to the directory and run git pull
        (cd "$TPM_DIR" && run git pull)
    fi
fi

# 4. FINAL INSTRUCTIONS
LOG_WARN "Tmux setup requires a final manual step:"
LOG_WARN "  1. Start Tmux: tmux"
LOG_WARN "  2. Inside Tmux, press PREFIX (C-b) + I to fetch and install the plugins listed in ~/.tmux.conf."

LOG_SUCCESS "Tmux and TPM setup script completed! ⌨️"