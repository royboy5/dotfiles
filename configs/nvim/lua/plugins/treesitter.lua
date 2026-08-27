return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "javascript", "typescript", "tsx", "html", "css",
          "json", "lua", "python", "go", "rust", "markdown", "markdown_inline"
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}

