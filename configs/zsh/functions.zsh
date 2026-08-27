# Create a new directory and enter it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
  if [ -f "$1" ] ; then
    case "$1" in
      *.tar.bz2)    tar xjf "$1"    ;;
      *.tar.gz)     tar xzf "$1"    ;;
      *.bz2)        bunzip2 "$1"    ;;
      *.rar)        unrar e "$1"    ;;
      *.gz)         gunzip "$1"     ;;
      *.tar)        tar xf "$1"     ;;
      *.tbz2)       tar xjf "$1"    ;;
      *.tgz)        tar xzf "$1"    ;;
      *.zip)        unzip "$1"      ;;
      *.Z)          uncompress "$1" ;;
      *.7z)         7z x "$1"       ;;
      *)            echo "'$1' cannot be extracted via extract()" ;;
    esac
  else  
    echo "'$1' is not a valid file"
  fi
}

# Outputs the name of the current branch
# Usage example: git pull origin $(git_current_branch)
function git_current_branch() {
  local branch
  branch=$(git branch --show-current 2> /dev/null)
  if [[ -n "$branch" ]]; then
    echo "$branch"
    return 0
  fi
  # Fallback for detached HEAD
  git rev-parse --short HEAD 2> /dev/null
}

# Update all git-based zsh plugins in PLUGIN_DIR
function update_zsh_plugins() {
  local plugin_dir="${PLUGIN_DIR:-$HOME/src/zsh-plugins}"
  if [[ ! -d "$plugin_dir" ]]; then
    echo "Plugin directory not found: $plugin_dir"
    return 1
  fi

  for repo in "$plugin_dir"/*; do
    if [[ -d "$repo/.git" ]]; then
      echo "==> Updating $(basename "$repo")..."
      git -C "$repo" pull --ff-only
    fi
  done
  echo "✅ Zsh plugins updated."
}
