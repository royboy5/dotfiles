-- ~/.config/nvim/lua/config/options.lua
-- :help options

local opt = vim.opt

-- =============================================================================
-- 1. LINE NUMBERS & DISPLAY
-- =============================================================================
opt.number = true                          -- Show line numbers
opt.relativenumber = true                  -- Show relative line numbers
opt.numberwidth = 4                        -- Number column width
opt.signcolumn = "yes"                     -- Always show sign column (prevents text shift)
opt.cursorline = true                      -- Highlight current line
opt.wrap = false                           -- Don't wrap long lines
opt.scrolloff = 8                          -- Minimal screen lines to keep above/below cursor
opt.sidescrolloff = 8                      -- Minimal screen columns to keep left/right of cursor
opt.termguicolors = true                   -- True color support
opt.conceallevel = 0                       -- Keep formatting characters visible in markdown
opt.cmdheight = 1                          -- Height of command line (1 saves vertical space)
opt.showmode = false                       -- Don't show mode (lualine handles this)
opt.showtabline = 2                        -- Always show tabline / bufferline
opt.pumheight = 10                         -- Max items in popup completion menu
opt.guifont = "monospace:h17"

-- =============================================================================
-- 2. TABS & INDENTATION
-- =============================================================================
opt.expandtab = true                       -- Convert tabs to spaces
opt.shiftwidth = 2                         -- Spaces per indentation level
opt.tabstop = 2                            -- Number of spaces a tab counts for
opt.smartindent = true                     -- Smarter auto-indenting

-- =============================================================================
-- 3. SEARCH & MATCHING
-- =============================================================================
opt.ignorecase = true                      -- Ignore case in search patterns
opt.smartcase = true                       -- Override ignorecase if search contains capitals
opt.hlsearch = true                        -- Highlight previous search pattern matches

-- =============================================================================
-- 4. SPLITS & WINDOWS
-- =============================================================================
opt.splitbelow = true                      -- Force horizontal splits below current window
opt.splitright = true                      -- Force vertical splits right of current window

-- =============================================================================
-- 5. SYSTEM, UNDO & BACKUPS
-- =============================================================================
opt.clipboard = "unnamedplus"              -- Sync with system clipboard
opt.undofile = true                        -- Persistent undo history across restarts
opt.swapfile = false                       -- Disable swapfiles
opt.backup = false                         -- Disable backup files
opt.writebackup = false                    -- Disable write backup
opt.timeoutlen = 400                       -- Time to wait for mapped keys / which-key (ms)
opt.updatetime = 300                       -- Faster completion and diagnostics refresh
opt.fileencoding = "utf-8"

-- =============================================================================
-- 6. COMPLETION, WRAPPING & FOLDING
-- =============================================================================
opt.completeopt = { "menuone", "noselect" }
opt.shortmess:append("c")                  -- Don't pass messages to |ins-completion-menu|
opt.whichwrap:append("<,>,[,],h,l")        -- Allow cursor keys to wrap lines
opt.iskeyword:append("-")                  -- Treat dash-separated words as single words
opt.mouse = "a"                            -- Enable mouse support

-- Native Treesitter Folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = true                      -- Enable folding
opt.foldlevelstart = 1                     -- Auto-fold functions/classes on open (level 1)
