# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

export EDITOR=nvim

# Paths
# export PATH=$HOME/.poetry/bin:$PATH
# export PATH=$HOME/sdks/flutter/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
# export PATH=$HOME/

# Volta
export VOLTA_HOME=$HOME/.volta
export PATH=$VOLTA_HOME/bin:$PATH

# Golang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# FZF
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi

. "$HOME/.cargo/env"
