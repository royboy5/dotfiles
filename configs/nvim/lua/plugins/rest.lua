-- rest.nvim: HTTP client for .http files. `:Rest run` sends the request under
-- the cursor; the http parser is in treesitter.lua's ensure_installed.
--
-- rest.nvim ships a rockspec, so lazy.nvim would install its dependencies with
-- luarocks, which needs luarocks, Lua 5.1 and a C compiler (its http grammar
-- rock fails to build). `build = false` turns that off; the dependencies are
-- plain lazy plugins instead.
return {
  "rest-nvim/rest.nvim",
  ft = "http",
  build = false,
  dependencies = {
    "nvim-neotest/nvim-nio",
    "j-hui/fidget.nvim",
    -- Plain Lua libraries (XML bodies, file body types), not nvim plugins:
    -- their modules sit at the repo root, so they go on package.path below.
    { "lunarmodules/lua-mimetypes", build = false },
    { "manoelcampos/xml2lua", build = false },
  },
  init = function()
    local root = require("lazy.core.config").options.root
    package.path = table.concat({
      package.path,
      root .. "/lua-mimetypes/?.lua",
      root .. "/xml2lua/?.lua",
    }, ";")
  end,
  keys = {
    { "<leader>rr", "<cmd>Rest run<cr>", desc = "Run HTTP request under cursor" },
    { "<leader>rl", "<cmd>Rest last<cr>", desc = "Re-run last HTTP request" },
  },
}
