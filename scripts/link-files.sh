# Symlink all config files

# Variables
DOTFILES_DIR=~/.dotfiles
DOTFILES_OLD=~/.dotfiles_old
CONFIG_FILES=("bashrc" "vimrc" "tmux.conf" "zshrc")

# functions
backup_file() {
    if [ -f "$DST" -o -d "$DST" -o -L "$DST" ]
    then
        echo "Backing up $DST..."
        mv $DST $DOTFILES_OLD
        echo "Done!"
    else
        echo "$DST does not exists"
    fi
}

link_file() {
    echo "Creating symlink to $SRC in home directory."
    ln -s $SRC $DST
}

# create .dotfiles_old in homedir
echo "Creating $DOTFILES_OLD for backup of any existing dotfiles in ~ ..."
mkdir -p $DOTFILES_OLD
echo "Done!"

# move any existing dotfiles in homedir to DOTFILES_OLD directory, 
# then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
# for file in $CONFIG_FILES; do
#     echo "Moving any existing dotfiles from ~ to $DOTFILES_OLD"
#     mv ~/.$file $DOTFILES_OLD
#     echo "Creating symlink to $file in home directory."
    
#     # ln -s $DOTFILES_DIR/$file ~/.$file
# done

for SRC in $(find "$DOTFILES_DIR" -maxdepth 2 -name '*.symlink')
do
    DST="$HOME/.$(basename "${SRC%.*}")"
    echo $DST
    backup_file
    link_file
done