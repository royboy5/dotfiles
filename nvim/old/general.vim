" GENERAL

set encoding=utf-8

set nocompatible

set clipboard=unnamedplus

" filetype plugin detection
filetype plugin indent on

" syntax highlighting
syntax enable
syntax on

" load theme
if (has("termguicolors")) 
 set termguicolors 
endif 

colorscheme onedark

" keeps 1000 items in history
set history=1000

" enable ruler
set ruler

" shows incomplete cmds
set showcmd

" shows autocomplete menu
set wildmenu

" shows line numbers
set number

" show relative numbers
set relativenumber

" shows highlight search
set hlsearch
set incsearch

" ignores case in search
set ignorecase

" use case if capital is detected
set smartcase

" line wrap
set lbr

" auto indent enabled
set ai

" smart indent enabled
set si

" shift and tab spaces
set shiftwidth=2
set tabstop=2

" tabs as spaces
set expandtab

" set fold to syntax
set foldmethod=syntax

" search index
set shortmess-=S

" Scroll offset
set scrolloff=8
