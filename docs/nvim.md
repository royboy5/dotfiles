[Home](/README.md) > Neovim

# Neovim

Neovim 0.12 with a Lua config, [lazy.nvim](https://github.com/folke/lazy.nvim)
for plugins, and Nix for everything outside the editor.

## How it fits together

| Piece | Managed by | Where |
|---|---|---|
| Neovim, `tree-sitter` CLI | Nix | `nix/home/nvim.nix` |
| Language servers, formatters | Nix, not an in-editor installer | `nix/home/nvim.nix` (gopls: `nix/home/dev/golang.nix`, zls: `nix/home/dev/zig.nix`) |
| `rust-analyzer` | rustup, so it matches your Rust toolchain | `rustup component add rust-analyzer` (bootstrap does this once) |
| Lua config | this repo, live-linked to `~/.config/nvim` | `configs/nvim/` |
| Plugins | lazy.nvim, pinned by commit | `configs/nvim/lazy-lock.json` |
| Treesitter parsers | nvim-treesitter, compiled on first start | `~/.local/share/nvim/site/parser/` |

Lua changes apply the next time you start nvim, with no rebuild. Only changes
in `nix/` (a new language server, a new Neovim) need `nrs`.

## Config layout

```
configs/nvim/
  init.lua                 # loads config.options, config.keymaps, config.lazy
  lazy-lock.json           # exact plugin commits (commit this)
  lua/config/
    options.lua            # editor settings
    keymaps.lua            # leader key + general keymaps
    lazy.lua               # bootstraps lazy.nvim, loads every file in lua/plugins/
  lua/plugins/             # one file per plugin (or group)
```

## Plugins

| Plugin | Used for |
|---|---|
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Pickers (files, grep, buffers), file explorer, floating terminal, lazygit, notifications |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Default settings per language server, enabled with Neovim's `vim.lsp.enable` |
| [fidget.nvim](https://github.com/j-hui/fidget.nvim) | LSP progress messages |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) + cmp sources | Completion |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatting, on save and with `<leader>fm` |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch) | Parser install; highlighting and indent are started per buffer |
| [nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring) | Correct comment syntax in embedded languages (JSX, templ) |
| [smart-splits.nvim](https://github.com/smart-splits-nvim/smart-splits.nvim) | Ctrl-hjkl across nvim splits and zellij panes (see [Zellij](zellij.md)) |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffers as tabs along the top |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs in the gutter, hunk preview, blame |
| [diffview-plus.nvim](https://github.com/dlyongemallo/diffview-plus.nvim) | Side-by-side git diffs |
| [kulala.nvim](https://github.com/mistweaverco/kulala.nvim) | HTTP client for `.http`/`.rest` files (has its own built-in language server) |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Shows the available keys after `<leader>` |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme |
| [cloak.nvim](https://github.com/laytan/cloak.nvim) | Masks values in `.env*` files |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs), [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Bracket pairs, indent guides |

## Language servers

Enabled in `lua/plugins/lsp.lua` (the `servers` list):

| Server | Languages | Comes from |
|---|---|---|
| `lua_ls` | Lua | `lua-language-server` |
| `ts_ls` | JavaScript, TypeScript | `typescript-language-server` |
| `eslint` | ESLint diagnostics | `vscode-langservers-extracted` |
| `biome` | JS/TS/JSON lint and format | the project's own `node_modules/.bin/biome` |
| `gopls` | Go | `gopls` |
| `rust_analyzer` | Rust | rustup component |
| `zls` | Zig | `zls` |

**Add a server:**
1. Add its package to `home.packages` in `nix/home/nvim.nix`
   ([package search](https://search.nixos.org/packages)) and run `nrs`.
2. Add its name ([list](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md))
   to `servers` in `lua/plugins/lsp.lua`. For custom settings, add a
   `vim.lsp.config("<name>", { … })` call next to the `lua_ls` one.
3. Restart nvim and check with `:checkhealth vim.lsp` (or `<leader>li`).

## Treesitter parsers

Installed on startup if missing: bash, c, css, dockerfile, go, html,
javascript, jsdoc, json, lua, markdown, markdown_inline, python, rust, templ,
tsx, typescript, vimdoc, yaml. A filetype with no parser installs one the first
time you open it. Add more to `ensure_installed` in `lua/plugins/treesitter.lua`.
They compile with the `tree-sitter` CLI from Nix.

## Keymaps

Leader is **Space**. Press it and wait to see everything in which-key.

| Keys | Action |
|---|---|
| `<C-h/j/k/l>` | Move between splits, and on into zellij panes at the edge |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<leader>e` | File explorer |
| `<leader>ff` / `<leader>fg` / `<leader>fb` | Find files / grep / buffers |
| `<leader>fm` | Format buffer |
| `<leader>la` / `<leader>lr` | Code action / rename |
| `<leader>lj` / `<leader>lk` / `<leader>lq` | Next / previous diagnostic / location list |
| `<leader>li` | LSP health (`:checkhealth vim.lsp`) |
| `K` | Hover docs |
| `<leader>gg` | lazygit |
| `]c` / `[c` | Next / previous git hunk |
| `<leader>gp` / `<leader>gb` / `<leader>gB` | Preview hunk / blame line / toggle line blame |
| `<leader>gt` | Diffview |
| `<leader>bp` / `<leader>bP` | Pin buffer / close unpinned buffers |
| `<leader>bo` / `<leader>br` / `<leader>bl` | Close other buffers / to the right / to the left |
| `<leader>c` / `<leader>w` / `<leader>q` | Close buffer / save / quit all |
| `<leader>/` | Toggle comment |
| `<leader>h` | Clear search highlight |
| `<leader>C` | Toggle cloak |
| `<leader>R…` | HTTP requests (kulala): `Rs` send, `Ra` send all, `Rc` copy as cURL |
| `<C-/>` | Floating terminal |
| `<leader>n` | Notification history |
| `<C-arrows>` | Resize split |
| `<A-j>` / `<A-k>` (visual) | Move selection down / up |

Completion (insert mode): `<C-j>`/`<C-k>` next/previous, `<CR>` confirm,
`<C-Space>` open the menu, `<C-e>` close it.

## Common tasks

| Task | How |
|---|---|
| Update plugins | `:Lazy update`, then commit `lazy-lock.json` |
| Add a plugin | New file in `lua/plugins/` returning a lazy.nvim spec; restart nvim |
| Same plugins as the lock file | `:Lazy restore` |
| Update Neovim or the language servers | `nfu`, then `nrs` |
| Health check | `:checkhealth`, or `:checkhealth vim.lsp` for language servers |

## Troubleshooting

- **A language server doesn't start.** `:checkhealth vim.lsp` and look for
  "not executable": the package is missing from `nix/home/nvim.nix` (for Rust,
  run `rustup component add rust-analyzer`). Logs are in
  `~/.local/state/nvim/lsp.log`.
- **Treesitter errors after updating plugins.** Run `:TSUpdate`.
- **A plugin's branch changed** (for example `attempt to call field … (a nil
  value)` right after pulling): lazy.nvim doesn't switch an installed plugin to
  another branch. Delete `~/.local/share/nvim/lazy/<plugin>` and restart nvim.
- **Plugins broken after `:Lazy update`.** `git checkout configs/nvim/lazy-lock.json`,
  then `:Lazy restore`.
