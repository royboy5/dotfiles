# Load all zsh configs
for config (~/.zsh/*.zsh) source $config

# Load plugins
source ~/.zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

eval "$(starship init zsh)"

neofetch
