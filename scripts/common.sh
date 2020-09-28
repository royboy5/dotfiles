# Common installs

# Functions
install_oh_my_zsh() {
    # Clone my oh-my-zsh repository from GitHub only if it isn't already present
    if [[ ! -d $HOME/.oh-my-zsh/ ]]; then
        echo "Cloning ohmyzsh repo..."
        git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
        echo "Done!"
    else
        echo ".oh-my-zsh directory already exists"
    fi
    # Set the default shell to zsh if it isn't currently set to zsh
    if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
        echo "Setting zsh as default shell"
        chsh -s $(which zsh)
        echo "Done!"
    else
        echo "Default shell is already zsh!"
    fi
}

echo "Installing common packages..."
install_oh_my_zsh
echo "Common packages installed!"
