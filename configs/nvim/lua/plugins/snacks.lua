return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- Enable the modules you want
			bigfile = { enabled = true }, -- Handle huge files nicely
			explorer = { enabled = true }, -- File Explorer (replacing Neo-tree)
			picker = {
				enabled = true,
				sources = {
					explorer = {
						hidden = true,
						ignored = true,
						auto_close = true,
						layout = { preset = "sidebar", preview = false },
					},
				},
			}, -- Fuzzy Finder (replacing Telescope)
			dashboard = { enabled = true }, -- Start screen
			notifier = { enabled = true }, -- VS Code style notifications
			quickfile = { enabled = true }, -- Faster startup for simple files
			input = { enabled = true }, -- VS Code style input prompts
			terminal = { enabled = true }, -- Built-in terminal toggle
		},
		keys = {
			-- 1. File Explorer (Sidebar)
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},

			-- 2. Fuzzy Finder (Files)
			{
				"<leader>ff",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep Text",
			},
			{
				"<leader>fb",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},

			-- 3. Terminal (Ctrl + /)
			{
				"<c-/>",
				function()
					Snacks.terminal()
				end,
				desc = "Toggle Terminal",
			},

			-- 4. LazyGit (if you have lazygit installed)
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>n",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "Notification History",
			},
		},
	},
}
