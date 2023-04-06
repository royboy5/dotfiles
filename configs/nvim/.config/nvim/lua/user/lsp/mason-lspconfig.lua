local status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if not status_ok then
    return
end

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
    return
end

mason_lspconfig.setup({
    ensure_installed = { "emmet_ls", "eslint", "graphql", "jsonls", "lua_ls", "rust_analyzer", "stylelint_lsp" },
    automatic_installation = true
})

mason_lspconfig.setup_handlers {
    function (server_name)
        lspconfig[server_name].setup {}
    end,
    ["emmet_ls"] = function ()
        lspconfig.emmet_ls.setup {}
    end,
    ["eslint"] = function ()
        lspconfig.eslint.setup {}
    end,
    ["graphql"] = function ()
        lspconfig.graphql.setup {}
    end,
    ["jsonls"] = function ()
        lspconfig.jsonls.setup {}
    end,
    ["lua_ls"] = function ()
        lspconfig.lua_ls.setup {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" }
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                            vim.api.nvim_get_runtime_file("", true),
                        },
                    },
                    telemetry = {
                        enable = false,
                    },
                }
            }
        }
    end,
    ["rust_analyzer"] = function ()
        lspconfig.rust_analyzer.setup {}
    end,
    ["stylelint_lsp"] = function ()
        lspconfig.stylelint_lsp.setup {
            settings = {
                stylelintplus = {
                    autoFixOnFormat = true,
                }
              }
        }
    end,
}