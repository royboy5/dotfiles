# Ubuntu installer

#Variables
PACKAGES=('curl' 'vim' 'tmux' 'zsh')

echo "Packages install script"

install_packages () {
    for PACKAGE in "${PACKAGES[@]}"; do
        echo "Installing $PACKAGE..."
        sudo apt-get install -y $PACKAGE
    done

    echo "Finished installing packages!"
}

echo "Installing packages..."
install_packages
echo "Packages installed!"

echo "Configuring system..."
# configure packages
# set zsh as default shell
chsh -s $(which zsh)

echo "Linking dotfiles..."
scripts/link-files.sh
