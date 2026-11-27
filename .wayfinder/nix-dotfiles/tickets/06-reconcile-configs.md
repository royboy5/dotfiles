---
title: Reconcile drifted configs
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

nvim, zellij, tmux and git have diverged between this repo and `~/.dotfiles`. Ghostty, starship and a global git ignore exist only there. Tool by tool, which pieces of each version go into the ported config? The `~/.dotfiles` version is the baseline, but this repo's current config must be weighed. Get explicit user confirmation for each config.

## Resolution

Decided with the user on 2026-11-10, tool by tool. Every config stays a linked file via `linkConfig`.

- **git:** start from `~/.dotfiles/configs/git/config` (`pager = delta`, `interactive.diffFilter = delta --color-only`, `autoSetupRemote` spelling fixed). Email is `me@royeng.com`. **Global git ignore contains only `.direnv/` and `.envrc`.** It's a new `configs/git/ignore` with `excludesfile = ~/.config/git/ignore`. None of the other entries in the `~/.dotfiles` ignore are ported. (Amended 2026-11-10: first decided as no global ignore, then reinstated with just these two lines.) delta joins the Nix git package set.
- **tmux:** this repo's config carries over unchanged, renamed `configs/tmux/tmux.conf`. The work-only k8s status segment stays out. Plugins remain on TPM: the bootstrap clones TPM, then `prefix + I` once.
- **zellij:** use the short `~/.dotfiles` `config.kdl` (defaults plus overrides), not this repo's 593-line dump. Changes:
  - drop `copy_command "pbcopy"` and rely on OSC 52
  - drop the normal-mode Ctrl-h/j/k/l focus binds (they clash with nvim window navigation)
  - drop the Ctrl-m Move-mode bind (Ctrl-m is Enter without the kitty keyboard protocol)
  - keep Ctrl-Shift-h/l tab switching, the Ctrl-q unbind with quit on Ctrl-o q, and `Alt d` / Ctrl-t d for the dev layout
  - remove the `cwd "/Users/reng/projects/vioc"` lines from `layouts/dev.kdl`

  Seamless nvim↔zellij navigation is deferred to [Seamless nvim–zellij navigation](10-nvim-zellij-navigation.md).
- **nvim:** this repo's config is the base (its plugin set: conform, gitsigns, lualine, kulala, autopairs, indent-blankline; its `desc`-labelled keymaps). From `~/.dotfiles`, take:
  - the `main`-branch treesitter config, with this repo's parsers (python, go, html, markdown, markdown_inline) merged into its list
  - the Shift-h/l keymaps moved into `bufferline.lua`
  - **fidget.nvim**

  Comment.nvim is not taken; nvim's built-in `gc` covers commenting.
- **nvim language servers and formatters:** Nix provides them in `nvim.nix`. Mason (`mason`, `mason-lspconfig`, `mason-tool-installer`) is removed from `lsp.lua`. Nix declares lua_ls, ts_ls, eslint (`vscode-langservers-extracted`), kulala_ls, stylua, prettier, black and isort. gopls and rust-analyzer are left to [Language toolchains and dev shells](08-toolchains-devshells.md). biome stays project-local via `pnpm exec`.
- **ghostty:** port the `~/.dotfiles` config with these changes:
  - drop `macos-titlebar-style`
  - set the theme to `TokyoNight Storm`
  - drop the `super+h/j/k/l` split binds (they would clash with Hyprland)

  Link it only on GUI hosts (Arch, Bazzite, `wing-zero`), not `wsl`. The font stays `FiraCode Nerd Font Mono`; how it's installed is left to the Fonts fog.
- **starship:** port the `~/.dotfiles` `starship.toml` without the kubernetes module or its GKE context pattern. Keep the `DEV_SHELL` segment provisionally; [Language toolchains and dev shells](08-toolchains-devshells.md) keeps or drops it.

Implementation still confirms each config with the user before adopting it (map Notes).
