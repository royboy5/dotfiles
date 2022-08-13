# Dotfiles

## Overview
This repo simplif

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

## Troubleshooting
- error while reading shada
  - clear `~/.local/share/nvim/shada` folder

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
- [awesome-neovim](https://github.com/rockerBOO/awesome-neovim)
- [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [jsonls schemas]( https://www.schemastore.org/json/)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [nvim-telescope](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [nvim-autopairs](https://github.com/windwp/nvim-autopairs)
- [Comment.nvim](https://github.com/numToStr/Comment.nvim)
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
- [nvim-tree](https://github.com/kyazdani42/nvim-tree.lua)
- [nvim-tree keybindings](https://github.com/kyazdani42/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt#L976)
- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- [vim-bbye](https://github.com/moll/vim-bbye)
- [null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim)
- [null-ls support](https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins) 
- [lualine](https://github.com/nvim-lualine/lualine.nvim)
- [impatient.nvim](https://github.com/lewis6991/impatient.nvim)
- [indent-blankline](https://github.com/lukas-reineke/indent-blankline.nvim)
- [alpha-nvim](https://github.com/goolord/alpha-nvim)
- [whichkey](https://github.com/folke/which-key.nvim)
- [project.nvim](https://github.com/ahmedkhalf/project.nvim)
- [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag)
- [zsh prompt](https://subscription.packtpub.com/book/application-development/9781783282937/1/ch01lvl1sec10/the-shell-prompt)
- [zsh files](https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout)
- [zsh startup files loading order](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)
- [awesome-dotfiles](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

## Troubleshooting
- Not sure why nvim-treesitter throws an error when installig for the 1st time.  Restart nvim and let the languages install.

## Ansible
- List of [ansible-facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vars_facts.html) 
