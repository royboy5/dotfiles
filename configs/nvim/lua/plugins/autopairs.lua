return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  dependencies = { "hrsh7th/nvim-cmp" },
  config = function()
    require("nvim-autopairs").setup({
      -- Use Treesitter to check for pair validity
      check_ts = true,
      ts_config = {
        lua = { "string", "source" },
        javascript = { "string", "template_string" },
        java = false,
      },
      -- Don't add pairs if the next char is alphanumeric
      ignored_next_char = "[%w%.]", 
      -- Enable/Disable fast wrap
      fast_wrap = {
        map = "<M-e>",
        chars = { "{", "[", "(", '"', "'" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
        offset = 0,
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "PmenuSel",
        highlight_grey = "LineNr",
      },
    })

    -- If you use nvim-cmp, this makes it so selecting "print" becomes "print()"
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}
