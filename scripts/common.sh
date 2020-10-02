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

install_vim_plugins() {
  # NERDTree
  echo "Installing NERDTree"
  git clone https://github.com/preservim/nerdtree.git ~/.vim/pack/vendor/start/nerdtree
  vim -u NONE -c "helptags ~/.vim/pack/vendor/start/nerdtree/doc" -c q
  echo "Done!"

  # Vim Polyglot
  echo "Installing Vim Polyglot"
  git clone --depth 1 https://github.com/sheerun/vim-polyglot ~/.vim/pack/plugins/start/vim-polyglot
  echo "Done!"
}

install_nvm() {
    # Checks to see if NVM is installed
    if [[ ! -d $HOME/.nvm/ ]]; then
        echo "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
        echo "NVM installed!"
    else
        echo ".nvm directory already exists"
    fi

}

install_poetry() {
    echo "Installing poetry..."
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
    echo "Poetry installed!"
}

echo "Installing common packages..."
install_oh_my_zsh
install_vim_plugins
install_nvm
install_poetry
echo "Common packages installed!"
