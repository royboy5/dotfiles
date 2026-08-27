return {
  "mistweaverco/kulala.nvim",
  -- 1. LAZY LOADING
  -- Only load this plugin when opening .http or .rest files
  ft = { "http", "rest" },

  -- 2. KEYBINDINGS
  -- These map <leader>R to "Rest" actions
  keys = {
    { "<leader>R", "", desc = "+Rest" },
    { "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send Request" },
    { "<leader>Ra", "<cmd>lua require('kulala').run_all()<cr>", desc = "Send All Requests" },
    { "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle Headers/Body" },
    { "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Prev Request" },
    { "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Next Request" },
    { "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL" },
    { "<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "Inspect Request" },
    { "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", desc = "Close Window" },
  },

  -- 3. SETTINGS
  opts = {
    -- "body" shows only the body by default. Use "full" for headers+body.
    default_view = "body", 
    -- Disable the default winbar if you find it cluttering
    winbar = false,
    -- Icons for the status
    icons = {
      inlay = {
        loading = "⏳",
        done = "✅",
        error = "❌",
      },
      lualine = "🐼",
    },
    -- Set to true if you want verbose logs for debugging
    debug = false,
  },
}