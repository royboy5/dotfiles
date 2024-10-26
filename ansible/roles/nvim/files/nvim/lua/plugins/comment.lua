return {
    {
        -- https://github.com/numToStr/Comment.nvim
        "numToStr/Comment.nvim", -- Easily comment stuff
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring", -- Treesitter context for comments
        },
        config = function()
            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
        end
    }
}
