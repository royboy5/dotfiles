return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" },
  opts = {
    global_keymaps = false,
    global_keymaps_prefix = "<leader>R",
    kulala_keymaps_prefix = "",
  },
  keys = {
    { "<leader>Rs", "<cmd>KulalaSend<cr>", desc = "Send request" },
    { "<leader>Ra", "<cmd>KulalaSendAll<cr>", desc = "Send all requests" },
    { "<leader>Rb", "<cmd>KulalaScratchpad<cr>", desc = "Open scratchpad" },
  },
}
