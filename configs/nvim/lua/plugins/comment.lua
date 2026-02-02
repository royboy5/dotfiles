return {
    {
        -- https://github.com/numToStr/Comment.nvim
        "numToStr/Comment.nvim", -- Easily comment stuff
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring", -- Treesitter context for comments
        },
keys = {
            -- 1. Normal Mode (Toggle current line)
            { 
                "<leader>/", 
                function() require("Comment.api").toggle.linewise.current() end, 
                mode = "n", 
                desc = "Toggle Comment" 
            },
            -- 2. Visual Mode (Toggle selection)
            -- Note: We use <ESC> first to ensure the visual selection markers are updated
            { 
                "<leader>/", 
                "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", 
                mode = "v", 
                desc = "Toggle Comment" 
            },
        },
        config = function()
            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
        end
    }
}
