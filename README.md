# Dotfiles

## Overview

## Prerequisite
- git
- fzf
- ripgrep
- [nerd-fonts](https://github.com/ryanoasis/nerd-fonts]

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
### onedark theme in lightline and airline
```
cp ~/.local/share/nvim/plugged/onedark.vim/autoload/lightline/colorscheme/onedark.vim ~/.local/share/nvim/plugged/lightline.vim/autoload/lightline/colorscheme/
cp ~/.local/share/nvim/plugged/onedark.vim/autoload/airline/themes/onedark.vim ~/.local/share/nvim/plugged/vim-airline/autoload/airline/themes/
```

## Troubleshooting
- error while reading shada
  - clear `~/.local/share/nvim/shada` folder
