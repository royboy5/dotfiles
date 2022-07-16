" NERDTree

" Ctrl-n to toggle
map <C-n> :NERDTreeToggle<CR>

" show hidden files
let NERDTreeShowHidden=1

" Closes NERDTree on file open
let NERDTreeQuitOnOpen=3

" hide helper
let g:NERDTreeMinimalUI = 1

" ignore node_modules to increase load speed 
let g:NERDTreeIgnore = ['^node_modules$']

" set to empty to use lightline
let g:NERDTreeStatusline = '' 

" Close window if NERDTree is the last one
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
