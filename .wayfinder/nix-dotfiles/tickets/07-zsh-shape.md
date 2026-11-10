---
title: Zsh: Nix-declared or linked files
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Should zsh be declared through home-manager's `programs.zsh` (as in `~/.dotfiles`), or should this repo's `.zshrc`/`aliases.zsh`/`functions.zsh` stay linked files? Decide where aliases, functions, plugins (zsh-autocomplete etc.), history (XDG state dir, per the recent commit) and zellij auto-start live.

## Resolution

Decided with the user on 2026-11-10.

- **Declared, not linked.** zsh is declared with home-manager's `programs.zsh` (`dotDir = ~/.config/zsh`), ported from `~/.dotfiles/nix/home/shell/zsh.nix` without Homebrew, Docker Desktop or `ndr`. This is the one deliberate exception to [Reconcile drifted configs](06-reconcile-configs.md)' "every config stays a `linkConfig` link": the plugins need store paths, and other modules feed zsh aliases, env vars and PATH. `configs/zsh/` and `os/arch/zsh/install.sh` are retired. The distro `/usr/bin/zsh` stays the login shell and reads the home-manager-written `~/.zshenv`/`.zshrc`.
- **Plugins:** zsh-autocomplete from `pkgs`, sourced at `lib.mkOrder 550` with `enableCompletion = false`. `autosuggestion.enable` and `syntaxHighlighting.enable` via home-manager (which loads highlighting last). `~/src/zsh-plugins` and `update_zsh_plugins` are deleted; plugin updates come with `nix flake update`.
- **History:** this repo's settings: `$XDG_STATE_HOME/zsh/history`, size/save 10000, and the full current option set (`EXTENDED_HISTORY`, `HIST_EXPIRE_DUPS_FIRST`, `HIST_IGNORE_DUPS`, `HIST_IGNORE_ALL_DUPS`, `HIST_IGNORE_SPACE`, `HIST_FIND_NO_DUPS`, `HIST_SAVE_NO_DUPS`, `HIST_REDUCE_BLANKS`, `HIST_VERIFY`, `INC_APPEND_HISTORY`, `SHARE_HISTORY`). Also `setopt AUTO_CD`.
- **Zellij auto-start:** on by default on every host (when zellij exists and `$ZELLIJ` is unset). Opt-out is `ZELLIJ_AUTOSTART=0`, set in `local_env.zsh` (per machine) or inline (`ZELLIJ_AUTOSTART=0 zsh`). The auto-start block runs after `local_env.zsh` is sourced. Documented in a comment in `zsh.nix` and in the zsh doc.
- **Aliases and env vars:** each topic module owns its own `home.shellAliases`/`home.sessionVariables`, as in `~/.dotfiles`: eza/bat/rg/fd and the fzf vars in `cli.nix`, git aliases in `git.nix`, `vi`/`vim`/`v` and `EDITOR`/`VISUAL` in `nvim.nix`, `nrs`/`dot` in the shell module. `zsh.nix` keeps only general ones (safety, navigation, `reload`). `aliases.zsh` and `env.zsh` are retired.
- **Functions:** `git_current_branch` (used by `ggpull`/`ggpush`/`gpsup`) in `git.nix` via `programs.zsh.initContent`. `mkcd` and `extract` in `zsh.nix`.
- **Alias conflicts:** `lg` = `lazygit` (gitui is not installed). Add `find` = `fd`. `reload` = `exec zsh`. Keep `dl`, `dt`, `src`, and `dot` = `cd ~/.dotfiles`. Drop `alias ~='cd ~'` (`AUTO_CD` covers it). The exact alias set is still confirmed with the user during implementation, per the map's Notes.
- **`env.zsh` cleanup:** drop Homebrew, Docker Desktop completions, the macOS Android path and `typeset -U PATH`. Keep `~/.local/bin` (`home.sessionPath`). proto, pnpm, cargo, opencode, flutter and the Android SDK go to [Language toolchains and dev shells](08-toolchains-devshells.md).
- **Secrets:** one gitignored `~/.config/zsh/local_env.zsh`, sourced at the end of `initContent`, with `local_env.zsh.sample` in the repo. The `local_envs.zsh` spelling is dropped. No sops/agenix. (Clears the map's "Secrets and local overrides" fog.)
