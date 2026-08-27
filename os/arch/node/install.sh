#!/usr/bin/env bash
set -e
source "${ROOT_DIR}/lib/helpers.sh"

# --- NODE.JS (via Volta) ---

# 1. Install Volta if missing
if ! command -v volta &> /dev/null; then
    LOG_INFO "Installing Volta (Fast Node.js version manager)..."
    
    if [[ "${DRY_RUN}" == true ]]; then
        echo "[DRY] Would install Volta"
    else
        # --skip-setup prevents modification of .bashrc/.zshrc
        # Assumes you manage your own PATH in your dotfiles
        curl https://get.volta.sh | bash -s -- --skip-setup
        
        # Critical: Export path for THIS session so the next commands work immediately
        export VOLTA_HOME="$HOME/.volta"
        export PATH="$VOLTA_HOME/bin:$PATH"
    fi
else
    LOG_SUCCESS "Volta is already installed"
fi

# 2. Use Volta to install Node and Tools
if command -v volta &> /dev/null; then

    # Install Node.js LTS
    # We check `command -v node` instead of parsing `volta list`
    if ! command -v node &> /dev/null; then
        LOG_INFO "Installing Node.js LTS via Volta..."
        run volta install node
    else
        LOG_SUCCESS "Node.js is already installed ($(node --version))"
    fi

    # Install pnpm
    LOG_INFO "Installing / updating pnpm via Volta..."
    run volta install pnpm

else
    LOG_WARN "Skipping Node/pnpm installation because Volta failed to install."
fi
