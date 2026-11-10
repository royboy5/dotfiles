-- ~/.config/nvim/lua/config/keymaps.lua

-- Set leader keys first
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Shorten function name
local keymap = vim.keymap.set
local opts = { silent = true }

-- Remap Space as leader (empty so it doesn't do anything by default)
keymap("", "<Space>", "<Nop>", opts)

-- NORMAL MODE --
-- Ctrl-h/j/k/l (splits + zellij panes): plugins/smart-splits.lua
-- Shift-h/l (buffers): plugins/bufferline.lua

keymap("n", "<leader>c", "<cmd>bd!<cr>", { desc = "Close Buffer" })
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save File" })
keymap("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit All" })
keymap("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear Highlights" })
keymap("n", "<leader>/", "gcc", { remap = true, desc = "Toggle Comment" })
keymap("v", "<leader>/", "gc", { remap = true, desc = "Toggle Comment" })

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Resize Up" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Resize Down" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize Left" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize Right" })

-- VISUAL MODE --

-- Stay in indent mode (Don't lose selection after shifting)
keymap("v", "<", "<gv", { desc = "Indent Left" })
keymap("v", ">", ">gv", { desc = "Indent Right" })

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", { desc = "Move Selection Down" })
keymap("v", "<A-k>", ":m .-2<CR>==", { desc = "Move Selection Up" })
keymap("v", "p", '"_dP', { desc = "Paste (Keep Yank)" }) -- Keep clipboard after paste

-- VISUAL BLOCK MODE --

-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move Block Down" })
keymap("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move Block Up" })
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", { desc = "Move Block Down" })
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", { desc = "Move Block Up" })

-- TERMINAL MODE --

-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", { desc = "Term Left" })
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", { desc = "Term Down" })
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", { desc = "Term Up" })
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", { desc = "Term Right" })