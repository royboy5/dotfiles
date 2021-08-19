# Dotfiles

## Overview

## Prerequisite
- git
- fzf
- ripgrep

## Install
```
$  git clone https://github.com/royboy5/dotfiles.git ~/.dotfiles
$  cd ~/.dotfiles
$  chmod +x -R install.sh scripts/
$  ./install.sh
```

## Post Install
- Set up your node version with nvm

## neoVim
Config
```
$HOME/.config/nvim/init.vim
```
Plugins location
```
$HOME/.local/share/nvim/plugged
```

## vim-plug
### Vim (~/.vim/autoload)
```
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```
### Neovim (~/.local/share/nvim/site/autoload)
```
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## Troubleshooting
- error while reading shada
  - clear `~/.local/share/nvim/shada` folder
