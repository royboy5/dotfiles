# =============================================================================
# 0. CONFIG ROOT
# =============================================================================
# Use ZDOTDIR (set in .zshenv), defaulting to standard path if missing.
# This allows the config to be portable.
ZSH_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"

# Safety Check
if [[ ! -d "$ZSH_ROOT" ]]; then
    echo "ERROR: Configuration directory not found at $ZSH_ROOT"
    return 1
fi

# =============================================================================
# 1. INITIALIZATION & PATHS
# =============================================================================

# Initialize Homebrew (Mac specific - fails silently on Arch)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Source your custom environment variables & PATHs
[[ -f "$ZSH_ROOT/env.zsh" ]] && source "$ZSH_ROOT/env.zsh"

# Source Secrets (Gitignored file)
[[ -f "$ZSH_ROOT/local_env.zsh" ]] && source "$ZSH_ROOT/local_env.zsh"

# =============================================================================
# 2. PLUGIN SETUP (PART 1)
# =============================================================================
PLUGIN_DIR="$HOME/src/zsh-plugins"

# Autocomplete (MUST run early, before compinit)
# zsh-autocomplete manages its own compinit, so we load it first
if [ -f "$PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
    source "$PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
else
    # Fallback: If plugin missing, use built-in completion
    # The -C flag uses the cache file to speed up startup time significantly
    autoload -Uz compinit && compinit -C
fi

# =============================================================================
# 3. PROMPT & OPTIONS
# =============================================================================

# Starship Prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# History Options
setopt histignorealldups sharehistory
HISTSIZE=5000
SAVEHIST=5000
# Save history in the config dir, keeping $HOME clean
HISTFILE="$ZSH_ROOT/.zsh_history"

# Colors
autoload -Uz colors && colors

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# =============================================================================
# 4. ALIASES & FUNCTIONS
# =============================================================================

# Load Aliases
if [[ -f "$ZSH_ROOT/aliases.zsh" ]]; then
    source "$ZSH_ROOT/aliases.zsh"
fi

# Load Functions (Contains your update_zsh_plugins function)
if [[ -f "$ZSH_ROOT/functions.zsh" ]]; then
    source "$ZSH_ROOT/functions.zsh"
fi

# =============================================================================
# 5. PLUGIN SETUP (PART 2 - The "Late Loaders")
# =============================================================================

# Autosuggestions (Grey text)
if [ -f "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax Highlighting (MUST BE LAST)
# If this runs before other widgets, it will break/override them
if [ -f "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi