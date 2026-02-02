return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
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
			{ "<leader>li", "<cmd>LspInfo<cr>", desc = "LSP Info" },
			{ "<leader>lI", "<cmd>Mason<cr>", desc = "Manage Tools (Mason)" },
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("mason").setup({
				ui = { icons = { server_installed = "✓", server_pending = "➜", server_uninstalled = "✗" } },
			})

			-- 1. INSTALL EVERYTHING HERE (LSPs + Formatters)
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- LSPs (The Brains)
					"lua_ls",
					"ts_ls",
					"gopls",
					"rust_analyzer",
					"eslint",
					"kulala_ls",
					-- Formatters (The Cleaners)
					"stylua",
					"prettier",
					"black",
					"isort",
				},
			})

			-- 2. CONFIGURE LSPs
			require("mason-lspconfig").setup({
				automatic_installation = false,
				handlers = {
					function(server_name)
						lspconfig[server_name].setup({ capabilities = capabilities })
					end,
					["eslint"] = function()
						require("lspconfig").eslint.setup({
							capabilities = capabilities,
							-- Force the server to start at the Monorepo Root (.git folder)
							-- This allows it to find the plugins you installed with -w
							root_dir = require("lspconfig.util").root_pattern(
								"pnpm-workspace.yaml",
								"turbo.json",
								".git"
							),
							workingDirectories = { mode = "auto" },
							on_new_config = function(config, new_root_dir)
								config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
									nodePath = new_root_dir .. "/node_modules",
								})
							end,
						})
					end,
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									runtime = { version = "Lua 5.1" },
									diagnostics = { globals = { "vim", "it", "describe", "before_each", "after_each" } },
								},
							},
						})
					end,
				},
			})

			-- 3. DIAGNOSTICS UI (Fixed Deprecation Warning)
			vim.diagnostic.config({
				-- This new syntax replaces the old 'sign_define' loop
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = "󰠠 ",
						[vim.diagnostic.severity.INFO] = " ",
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
