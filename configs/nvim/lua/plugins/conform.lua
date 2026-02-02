return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    -- Auto-format on save
    format_on_save = { timeout_ms = 1000, lsp_fallback = true },
    
    -- Define formatters
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      python = { "isort", "black" },
      go = { "gofmt" },
      rust = { "rustfmt" },
      lua = { "stylua" },
    },
  },
}
