return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>fm",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		-- Auto-format on save
		format_on_save = { timeout_ms = 1000, lsp_fallback = true },

		-- Define formatters
		formatters_by_ft = {
			-- Biome handles these now (matches the biome LSP set up in lsp.lua).
			-- conform's built-in "biome" formatter resolves the project-local
			-- node_modules/.bin/biome on its own.
			javascript = { "biome" },
			typescript = { "biome" },
			javascriptreact = { "biome" },
			typescriptreact = { "biome" },
			json = { "biome" },
			jsonc = { "biome" },

			-- Left on prettier: Biome's CSS/HTML formatters exist but are newer
			-- and not yet fully prettier-compatible. Switch these to { "biome" }
			-- too if you'd rather have one tool handle everything.
			css = { "prettier" },
			html = { "prettier" },

			python = { "isort", "black" },
			go = { "gofmt" },
			rust = { "rustfmt" },
			lua = { "stylua" },
		},
	},
}
