local fn = vim.fn

-- Automatically install lazy.nvim 
-- data path ".local/share/nvim"
local lazy_path = fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazy_path) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazy_path,
  })
end
vim.opt.rtp:prepend(lazy_path)

-- load plugins
require("lazy").setup("plugins")