-- nvim-treesitter, `main` branch.
--
-- The `master` branch is frozen and does not support Neovim 0.12 (its own
-- README: "Neovim 0.12 is not supported"). On 0.12 its stale injection
-- queries crash vim.treesitter.get_range() with "attempt to call method
-- 'range' (a nil value)".
--
-- `main` is a different plugin in practice: there is no
-- `nvim-treesitter.configs`, and no `highlight`/`indent`/`ensure_installed`
-- options. The plugin now only installs parsers and queries; enabling
-- features is up to us, via the Neovim APIs below.
--
-- Requires the tree-sitter CLI (installed by Nix: nix/home/nvim.nix).

-- Parsers to install on startup. `templ` ships with `main`, so the custom
-- install_info block the old config carried is no longer needed.
local ensure_installed = {
  "bash",
  "c",
  "css",
  "dockerfile",
  "go",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "rust",
  "templ",
  "tsx",
  "typescript",
  "vimdoc",
  "yaml",
}

-- Replaces the old `indent = { disable = { "yaml" } }`.
local indent_disabled = { yaml = true }

-- Replaces `additional_vim_regex_highlighting = { "markdown" }`: run the
-- legacy syntax engine alongside treesitter for these filetypes.
local vim_regex_highlighting = { markdown = true }

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  -- `main` does not support lazy-loading.
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring", -- Treesitter context for comments
  },
  config = function()
    local ts = require("nvim-treesitter")

    ts.setup()

    -- Install anything missing, asynchronously.
    local installed = ts.get_installed("parsers")
    local missing = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, ensure_installed)
    if #missing > 0 then
      ts.install(missing)
    end

    -- Start treesitter per buffer. On `main` this is the replacement for
    -- `highlight = { enable = true }` and `indent = { enable = true }`.
    local function start(buf, ft)
      pcall(vim.treesitter.start, buf)
      if not indent_disabled[ft] then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
      if vim_regex_highlighting[ft] then
        -- vim.treesitter.start() clears &syntax (see runtime highlighter.lua,
        -- `vim.bo[self.bufnr].syntax = ''`), so re-enable the legacy engine
        -- after the FileType autocmd chain has finished.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].syntax = ft
          end
        end)
      end
    end

    -- Tracks in-flight installs so a burst of FileType events for the same
    -- language doesn't kick off duplicate compiles.
    local installing = {}

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("nvim_treesitter_start", { clear = true }),
      callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        if vim.tbl_contains(ts.get_installed("parsers"), lang) then
          start(ev.buf, ft)
        elseif not installing[lang] and vim.tbl_contains(ts.get_available(), lang) then
          -- Stands in for the old `auto_install = true`.
          installing[lang] = true
          ts.install({ lang }):await(vim.schedule_wrap(function()
            installing[lang] = nil
            if vim.api.nvim_buf_is_valid(ev.buf) then
              start(ev.buf, ft)
            end
          end))
        end
      end,
    })

    require("ts_context_commentstring").setup({
      enable_autocmd = false,
    })

    vim.g.skip_ts_context_commentstring_module = true
  end,
}
