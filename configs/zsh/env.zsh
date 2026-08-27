# =============================================================================
# CORE PATH CONFIGURATION
# =============================================================================

# Ensure unique PATH entries
typeset -U PATH path

# Standard user bins
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Homebrew (macOS specific) - Only add if directory exists
if [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# =============================================================================
# 3. LANGUAGE & FRAMEWORK PATHS
# =============================================================================

# --- PROTO ---
export PROTO_HOME="$HOME/.proto"
if [[ -d "$PROTO_HOME" ]]; then
    export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# --- OPENCODE ---
if [[ -d "$HOME/.opencode/bin" ]]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi


# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# --- RUST ---
# Sourcing env is the official way, as it handles PATH + other necessary vars
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
else
    # Fallback if env file missing
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# --- FLUTTER ---
if [[ -d "$HOME/src/flutter/bin" ]]; then
    export PATH="$HOME/src/flutter/bin:$PATH"
fi

# --- ANDROID SDK ---
# Detects Linux vs macOS location
if [[ -d "$HOME/Android/Sdk" ]]; then
    # Standard Linux/Arch Path
    export ANDROID_HOME="$HOME/Android/Sdk"
elif [[ -d "$HOME/Library/Android/sdk" ]]; then
    # Standard macOS Path
    export ANDROID_HOME="$HOME/Library/Android/sdk"
fi

# If we found an Android SDK, add tools to PATH
if [[ -n "$ANDROID_HOME" ]]; then
    export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# =============================================================================
# 4. TOOL CONFIGURATION
# =============================================================================

# --- FZF ---
# Uses ripgrep if available
if command -v rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi

# --- DOCKER ---
# Docker Desktop (Mac) completions
if [[ -d "$HOME/.docker/completions" ]]; then
    fpath=("$HOME/.docker/completions" $fpath)
fi
