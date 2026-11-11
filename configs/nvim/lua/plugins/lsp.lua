return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"j-hui/fidget.nvim", -- LSP progress in the corner
		},
		keys = {
			-- ACTIONS
			{ "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
			{ "<leader>lr", vim.lsp.buf.rename, desc = "Rename Variable" },
			-- FORMATTING (Connects to Conform)
			{
				"<leader>lf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format Code",
			},
			-- DIAGNOSTICS
			{ "<leader>lj", vim.diagnostic.goto_next, desc = "Next Diagnostic" },
			{ "<leader>lk", vim.diagnostic.goto_prev, desc = "Prev Diagnostic" },
			{ "<leader>lq", vim.diagnostic.setloclist, desc = "Quickfix List" },
			-- INFO & TOOLS
			{ "<leader>li", "<cmd>checkhealth vim.lsp<cr>", desc = "LSP Info" },
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("fidget").setup({})

			-- 1. SERVERS: the binaries come from Nix (nix/home/nvim.nix and
			-- nix/home/dev/), not from a plugin. Add the package there and the
			-- name here. Formatters are wired in conform.lua.
			-- NOTE: "biome" is NOT installed by Nix. We run it via `pnpm exec biome`,
			-- i.e. the copy in the project's own node_modules. See the
			-- vim.lsp.config("biome", ...) block below for why this matters.
			-- kulala.nvim runs its own built-in LSP for .http files.
			local servers = {
				"lua_ls",
				"ts_ls",
				"eslint",
				"gopls",
				"rust_analyzer",
				"zls",
				"biome",
			}

			-- 2. GLOBAL DEFAULTS: applied to every server via vim.lsp.config("*", ...)
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- 3. PER-SERVER OVERRIDES
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "Lua 5.1" },
						diagnostics = { globals = { "vim", "it", "describe", "before_each", "after_each" } },
					},
				},
			})

			vim.lsp.config("eslint", {
				-- Force the server to start at the Monorepo Root (.git folder)
				-- This allows it to find the plugins you installed with -w
				root_dir = require("lspconfig.util").root_pattern("pnpm-workspace.yaml", "turbo.json", ".git"),
				settings = { workingDirectories = { mode = "auto" } },
				on_new_config = function(config, new_root_dir)
					if new_root_dir then
						config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
							nodePath = new_root_dir .. "/node_modules",
						})
					end
				end,
			})

			-- Biome: NOT installed by Nix. Runs the project-local binary via `pnpm exec`,
			-- which matters in a pnpm workspace/monorepo where different packages can
			-- pin different Biome versions.
			--
			-- NOTE: recent nvim-lspconfig versions already auto-detect
			-- `node_modules/.bin/biome` relative to root_dir and fall back to a global
			-- `biome` on $PATH, so if you don't specifically need pnpm's resolution
			-- behavior, you can likely drop the `cmd` override below entirely and just
			-- call vim.lsp.enable("biome").
			vim.lsp.config("biome", {
				cmd = { "pnpm", "exec", "biome", "lsp-proxy" },
				filetypes = {
					"javascript",
					"javascriptreact",
					"json",
					"jsonc",
					"typescript",
					"typescriptreact",
					"vue",
				},
				root_dir = require("lspconfig.util").root_pattern("biome.json", "biome.jsonc", "package.json", ".git"),
			})

			-- 4. ENABLE
			vim.lsp.enable(servers)

			-- 5. DIAGNOSTICS UI
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = "󰠠 ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
				virtual_text = true,
				update_in_insert = true,
				underline = true,
				severity_sort = true,
				float = {
					focusable = false,
					style = "minimal",
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
			})
		end,
	},
}
