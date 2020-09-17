# Symlink all config files

# Variables
DOTFILES_DIR=~/.dotfiles
DOTFILES_OLD=~/.dotfiles_old
CONFIG_FILES=("bashrc" "vimrc" "tmux.conf" "zshrc")

# create .dotfiles_old in homedir
echo "Creating $DOTFILES_OLD for backup of any existing dotfiles in ~ ..."
mkdir -p $DOTFILES_OLD
echo "done"

