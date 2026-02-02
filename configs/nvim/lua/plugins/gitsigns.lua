return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" }, -- Load when opening a file
    opts = {
      -- 1. Visuals
      signs = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      
      -- 2. Behavior
      attach_to_untracked = true, -- Recommend setting to true so you see new files in sidebar
      current_line_blame = false, -- Keep disabled by default (toggle with keymap)
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', 
        delay = 500, -- Faster delay (default 1000)
      },
      max_file_length = 40000, -- Performance boost for huge files
      preview_config = {
        border = "rounded", -- Matches your other UI
      },

      -- 3. Keymaps (The important part)
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next Hunk")

        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev Hunk")

        -- Actions
        map("n", "<leader>gp", gs.preview_hunk, "Preview Hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>gd", gs.diffthis, "Diff This")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle Line Blame")
        
        -- Text Objects (allows you to type 'dih' to delete inner hunk)
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
      end,
    },
  }
}