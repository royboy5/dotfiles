---
title: Seamless nvim–zellij navigation
type: task
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Requested by the user during [Reconcile drifted configs](06-reconcile-configs.md) as later work: make Ctrl-h/j/k/l move between nvim splits and zellij panes as one surface (e.g. the `zellij-nav` zellij plugin + `smart-splits.nvim`, or `vim-zellij-navigator`). Until then, zellij's normal-mode Ctrl-h/j/k/l are left unbound so nvim navigation works. Pick the plugin pair, wire the keybinds in `configs/zellij/config.kdl` and the nvim config, and confirm it works in Ghostty and Windows Terminal (`wsl`). The user chose to keep this in scope (2026-11-10) rather than defer it past the port.

## Resolution

Decided with the user on 2026-11-10. This is a decision only: wiring and testing happen during implementation, because the ported configs don't exist yet.

- **Plugin pair:** [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator) 0.3.0 on the zellij side, plus [smart-splits.nvim](https://github.com/smart-splits-nvim/smart-splits.nvim) `^3.0.0` with [backend-zellij-lua](https://github.com/smart-splits-nvim/backend-zellij-lua) v1 on the nvim side. All three were actively maintained as of Oct–Nov 2026. zellij-nav.nvim and the navigator-only setup were considered and rejected.
- **zellij (`configs/zellij/config.kdl`):** inside `shared_except "locked"`, bind `Ctrl h/j/k/l` to `MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm"`. Each bind uses `name "move_focus"`, `move_mod "ctrl"` and the matching `payload` (left/down/up/right). Put `move_mod` on every bind, because the plugin takes its config from the first command it runs. The release URL is pinned in the file; it is not fetched through Nix. Needs zellij ≥ 0.42.2, which nixpkgs-unstable meets.
- **At the edge:** focus stops (`move_focus`, not `move_focus_or_tab`). Tabs stay on Ctrl-Shift-h/l.
- **nvim:** add a new `lua/plugins/smart-splits.lua` with `mux.backend = 'smart-splits-backend-zellij-lua'`. Map `<C-h/j/k/l>` to `move_cursor_left/down/up/right`. Those maps replace the four `<C-w>h/j/k/l` normal-mode maps in `keymaps.lua`. The terminal-mode `<C-h/j/k/l>` maps stay. Insert-mode cmp `<C-j>/<C-k>` keeps working, because the navigator passes the key to nvim whenever nvim is focused.
- **Resize:** not wired. smart-splits can do Alt-hjkl resizing, but adding it was not decided here, so zellij's own Alt binds stay as they are.
- **Ctrl-l in shell panes:** the user accepts losing clear-screen and Ctrl-h as backspace. Use `clear` instead. No zsh rebind.
- **Acceptance check at implementation:** test in Ghostty (GUI hosts) and in Windows Terminal (`wsl`). Ctrl-hjkl should cross nvim splits ↔ zellij panes in both directions. Also check that the navigator still detects nvim when it runs through home-manager's wrapped `nvim` binary. Its detection relies on `zellij action list-clients`, and how that treats wrapped binaries isn't documented. Expect each direction to flash once per new session; this is a known upstream quirk.
