# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Paths
export PATH=$HOME/.poetry/bin:$PATH
export PATH=$HOME/sdks/flutter/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH

# Awesome WM
export EDITOR=nvim

# FZF
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi

# Chrome 
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable

. "$HOME/.cargo/env"
