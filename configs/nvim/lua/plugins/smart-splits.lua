-- Ctrl-h/j/k/l move between nvim splits and, at the edge of nvim, on to the
-- neighbouring zellij pane. The zellij side is vim-zellij-navigator
-- (configs/zellij/config.kdl), which hands these keys to nvim when it's focused.
return {
	"smart-splits-nvim/smart-splits.nvim",
	version = "^3.0.0",
	lazy = false, -- must be loaded for zellij to detect nvim
	dependencies = {
		{
			"smart-splits-nvim/backend-zellij-lua",
			version = "^1",
			main = "smart-splits-backend-zellij-lua",
			opts = {},
		},
	},
	opts = {
		mux = { backend = "smart-splits-backend-zellij-lua" },
	},
	keys = {
		{
			"<C-h>",
			function()
				require("smart-splits").move_cursor_left()
			end,
			desc = "Split/Pane Left",
		},
		{
			"<C-j>",
			function()
				require("smart-splits").move_cursor_down()
			end,
			desc = "Split/Pane Down",
		},
		{
			"<C-k>",
			function()
				require("smart-splits").move_cursor_up()
			end,
			desc = "Split/Pane Up",
		},
		{
			"<C-l>",
			function()
				require("smart-splits").move_cursor_right()
			end,
			desc = "Split/Pane Right",
		},
	},
}
