# Dotfiles

## Overview
This repo simplifies provisioning your computer.  

## TOC
1. [Prerequisite](#prerequisite)
2. [Installation](#installation)
3. [Post Install](#post-install)
4. [Links](#links)

## Prerequisite
- make

## Installation
- rename `configs/zsh/local_envs.zsh.sample` to `configs/zsh/local_envs.zsh`
- `$ make macosx` 

## Post Install
- Set up your node version with nvm
- :LspInstallInfo to select languages for LSP.

### Links
- [nvim](configs/nvim/README.md)
- [tmux](configs/tmux/README.md)
- [zsh](configs/zsh/README.md)

## Important Directories

### nvim 
config: `~/.config/nvim`
data: `~/.local/share/nvim/`
plugins: `~/.local/share/nvim/site/pack/packer/`
logs: `~/.cache`
state: `~/.local/state`

### Linux
fonts: `~/.local/share/fonts`

## Installing nerd-fonts
### Linux
- Manual
  - Goto [nerd-fonts](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/)
  - pick and download font
  - copy font files into `~/.local/share/fonts`
- Script
  - View `./scripts/install_firacode.sh` as an example and use your own font from nerd-fonts.
- Package Manager
  - Use your linux distro package manager to install font

### MacOS
In the downloaded TTF folder:

-  Select all font files
-  Right click and select Open (alternatively Open With Font Book)
-  Select "Install Font"

### Windows
In the ttf folder
- double-click each font file, click “Install font”
  - to install all at once, select all files, right-click, and choose “Install”

*On some systems (especially Windows 10), you may need to "Unblock" each font file before installing. To do so, right-click each font file, click Properties, then check Unblock next to Security at the bottom of the General tab. Click OK, and then install.

Or,
- On Windows 10 open the System Settings, 
- go to Fonts and drag and drop the the font files from the ttf folder into the drop area indicated at the top of the dialog.

## Helpful Links
- [nerd-fonts](https://www.nerdfonts.com/)
- [awesome-dotfiles](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)
- [https://starship.rs/](https://starship.rs/)
- [https://github.com/ogham/exa](https://github.com/ogham/exa)


## Troubleshooting
- error while reading shada
  - clear `~/.local/share/nvim/shada` folder
- Not sure why nvim-treesitter throws an error sometimes when installing for the 1st time.
  - Restart nvim and let the languages install.

## Ansible
- List of [ansible-facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html) 
