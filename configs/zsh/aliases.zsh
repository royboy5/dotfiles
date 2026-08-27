# =============================================================================
# 1. MODERN CORE REPLACEMENTS
# =============================================================================

# LS -> EZA
# --group-directories-first: lists folders before files
# --git: shows git status symbols
if command -v eza &> /dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --git --group-directories-first"
    alias lt="eza --tree --level=2 --icons"
fi

# CAT -> BAT
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'  # Plain for copying
    alias catp='bat'               # "Print" (formatted with paging)
fi

# GREP -> RIPGREP (rg)
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# =============================================================================
# 2. NAVIGATION & SYSTEM
# =============================================================================

# Safety first
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Shortcuts
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias src='cd ~/src'

# System Maintenance
alias reload='source "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc" && echo "✅ Zsh config reloaded."'

# =============================================================================
# 3. EDITORS
# =============================================================================
alias vi="nvim"
alias vim="nvim"
alias v="nvim"

# =============================================================================
# 4. GIT (Enhanced)
# =============================================================================

# The "Lazy" way
alias lg='gitui'

# Basics
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gs='git status'
alias gsb='git status -sb' # Short status with branch info

# Commit
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gcam='git commit -a -m'
alias gam='git commit --amend'
alias gamn='git commit --amend --no-edit' # Fix last commit quietly

# Branches
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D' # Force delete

# Checkout / Switch
alias gsw='git switch'
alias gswc='git switch -c'
alias gco='git checkout'
alias gcb='git checkout -b'

# Pull / Push
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease' # Safer than --force

# Context-aware Push/Pull (Requires git_current_branch function)
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpush='git push origin "$(git_current_branch)"'
alias gpsup='git push --set-upstream origin "$(git_current_branch)"'

# Logs
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glo='git log --pretty="format:%C(auto)%h %C(green)%an %C(blue)%ar %C(auto)%d %s"'

# Stash
alias gst='git stash'
alias gstp='git stash pop'
alias gstd='git stash drop'
alias gstl='git stash list'