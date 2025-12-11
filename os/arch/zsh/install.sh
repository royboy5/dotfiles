#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# Variables
# Zsh is installed via pacman, using the system binary path.
ZSH_BIN="/usr/bin/zsh"

# Configuration Paths
CONFIG_SOURCE="${ROOT_DIR}/configs/zsh"
CONFIG_TARGET="$HOME/.config/zsh"
ZSHENV_POINTER="$HOME/.zshenv"

# Plugin Source Path
PLUGINS_DIR="$HOME/src/zsh-plugins"

LOG_INFO "Setting up Zsh for Arch Linux (via Pacman)..."

# 1. INSTALL ZSH DEPENDENCIES
LOG_INFO "Installing zsh dependencies..."
run sudo pacman -S --needed --noconfirm zsh

# 2. CREATE DIRECTORIES
run mkdir -p "$HOME/src"

# 3. INSTALL PLUGINS
declare -a PLUGINS=(
    "https://github.com/marlonrichert/zsh-autocomplete.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

LOG_INFO "Installing zsh plugins to $PLUGINS_DIR..."
run mkdir -p "$PLUGINS_DIR"

for repo_url in "${PLUGINS[@]}"; do
    plugin_name=$(basename "$repo_url" .git)
    target_path="$PLUGINS_DIR/$plugin_name"
    
    if [[ ! -d "$target_path" ]]; then
        LOG_INFO "Cloning $plugin_name..."
        run git clone "$repo_url" "$target_path"
    else
        LOG_INFO "Updating $plugin_name..."
        if [[ "${DRY_RUN}" == true ]]; then
            LOG_INFO "[dry-run] cd '$target_path' && git pull"
        else
            (cd "$target_path" && run git pull)
        fi
    fi
done

# 4. LINK CONFIGURATION FILES
LOG_INFO "Linking zsh configuration files..."

# Link the entire config directory
run link_file "$CONFIG_SOURCE" "$CONFIG_TARGET"

# Link .zshenv to HOME
zshenv_source="${CONFIG_SOURCE}/.zshenv"
run link_file "$zshenv_source" "$ZSHENV_POINTER"

# 5. SET DEFAULT SHELL
LOG_INFO "Setting zsh as default shell..."

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    # Use sudo chsh since the Zsh binary is in a privileged location (/usr/bin/zsh)
    run sudo chsh -s "$ZSH_BIN"
    LOG_SUCCESS "Default shell changed to $ZSH_BIN"
else
    LOG_SUCCESS "Default shell is already zsh"
fi

LOG_SUCCESS "Zsh setup complete!"
LOG_INFO ""
LOG_INFO "Installation summary:"
LOG_INFO "  Zsh binary:      $ZSH_BIN"
LOG_INFO "  Config source:   $CONFIG_SOURCE"
LOG_INFO "  Config symlink:  ~/.config/zsh/ → $CONFIG_SOURCE"
LOG_INFO "  .zshenv symlink: ~/.zshenv → ${CONFIG_SOURCE}/.zshenv"
LOG_INFO ""
LOG_INFO "Please log out and back in for shell change to take effect."