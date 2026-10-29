return {
	{
		"dlyongemallo/diffview-plus.nvim",
		version = "*",
		-- 1. Keybinding to Toggle
		keys = {
			{ "<leader>gt", "<cmd>DiffviewToggle<cr>", desc = "Diffview" },
		},

		-- optional: lazy-load on command
		-- cmd = {
		--     "DiffviewOpen",
		--     "DiffviewToggle",
		--     "DiffviewFileHistory",
		--     "DiffviewDiffFiles",
		--     "DiffviewLog",
		-- },
	},
}
