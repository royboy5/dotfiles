return {
    {
        -- https://github.com/lukas-reineke/indent-blankline.nvim
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            local ibl = require("ibl")
            local highlight = {
                "CursorColumn",
                "Whitespace",
            }

            ibl.setup {
                indent = { highlight = highlight, char = "" },
                whitespace = {
                    highlight = highlight,
                    remove_blankline_trail = false,
                },
                scope = { enabled = false },
            }
        end
    }
}
