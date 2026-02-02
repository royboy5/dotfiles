return {
	"laytan/cloak.nvim",
	event = { "BufReadPre", "BufNewFile" },

	-- 1. Keybinding to Toggle
	keys = {
		{ "<leader>C", "<cmd>CloakToggle<cr>", desc = "Toggle Secrets (Cloak)" },
	},

	opts = {
		enabled = true,
		cloak_character = "*",
		highlight_group = "Comment",
		patterns = {
			-- Standard .env files
			{
				file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
				cloak_pattern = "=.+",
			},
			-- Kubernetes / YAML Secrets
			{
				file_pattern = { "*secret*.yaml", "*secret*.yml", "k8s-*.yaml" },
				cloak_pattern = ":.+",
			},
		},
	},
}

