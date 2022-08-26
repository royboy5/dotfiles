# Load all zsh configs
for config (~/.zsh/*.zsh) source $config

# Load colors 
autoload -Uz colors && colors

# Set up the prompt
autoload -Uz promptinit && promptinit
# prompt adam1

# Load theme
# source ~/.zsh/themes/agnoster.zsh-theme

setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

eval "$(starship init zsh)"
