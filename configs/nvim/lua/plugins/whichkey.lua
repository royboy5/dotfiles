return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern", -- "classic", "modern", "helix" (nice vertical layout)
		-- define your group labels here
		spec = {
			{
				mode = { "n" }, -- NORMAL
                { "<leader>b", group = "Buffers" },
                { "<leader>f", group = "Find (Snacks)" },
				{ "<leader>g", group = "Git" },
                { "<leader>l", group = "LSP" },
			},
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
