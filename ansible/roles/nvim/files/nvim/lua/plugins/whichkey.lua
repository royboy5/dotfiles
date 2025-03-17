return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      icons = {
        mappings = false
      },
    },
    config = function()
      local wk = require("which-key")
      
      wk.add({
        {
          mode = { "n", "v" }, -- NORMAL and VISUAL mode
          { "<leader>/", "<cmd>lua require(\"Comment.api\").toggle.linewise.current()<CR>", desc = "Comment" },
        },
        {
          mode = { "n" }, -- Normal mode only
          { "<leader>c", "<cmd>bd!<CR>", desc = "Close" },
          { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
          { "<leader>h", "<cmd>nohlsearch<CR>", desc = "No Highlight" },
          { "<leader>q", "<cmd>q!<CR>", desc = "Quit" },
          { "<leader>w", "<cmd>w!<CR>", desc = "Save" },
          { "<leader>W", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
          { "<leader>?", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
  
          -- Files Group
          { "<leader>f", group = "File" },
          { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
          { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
          { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },

          -- Git
          { "<leader>g", group = 'Git'},
          { "<leader>gj", "<cmd>lua require 'gitsigns'.next_hunk()<cr>", desc = "Next Hunk" },
          { "<leader>gk", "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", desc = "Prev Hunk" },
          { "<leader>gb", "<cmd>lua require 'gitsigns'.blame()<cr>", desc = "Blame" },
          { "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<cr>", desc = "Blame" },
          { "<leader>gp", "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", desc = "Preview Hunk" },
          { "<leader>gr", "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", desc = "Reset Hunk" },
          { "<leader>gR", "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", desc = "Reset Buffer" },
          { "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", desc = "Stage Hunk" },
          { "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", desc = "Undo Stage Hunk" },
          { "<leader>go", "<cmd>Telescope git_status<cr>", desc = "Open changed file" },
          { "<leader>gB", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
          { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit" },
          { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>", desc = "Diff" },

          -- LSP
          { "<leader>l", group = "LSP" },
          { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },
          { "<leader>lf", "<cmd>lua vim.lsp.buf.format { async = true }<cr>", desc = "Format" },
          { "<leader>li", "<cmd>LspInfo<cr>", desc = "Info" },
          { "<leader>lI", "<cmd>LspInstall<cr>", desc ="Installer Info" },
          { "<leader>lj", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", desc = "Next Diagnostic" },
          { "<leader>lk", "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", desc = "Prev Diagnostic" },
          { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action" },
          { "<leader>lq", "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", desc = "Quickfix" },
          { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },
          { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
          { "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },

          -- Search
          { "<leader>s", group = "Search" },
          { "<leader>sc", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
          { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
          { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
          { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
          { "<leader>sR", "<cmd>Telescope registers<cr>", desc = "Registers" },
          { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
          { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
        }
      })
    end
  }
}
