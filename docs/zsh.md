[Home](/README.md) > Zsh

# Zsh

The login shell on every host. Its package comes from the host's **system
layer** (so it can be in `/etc/shells`); its config comes from home-manager.

## Where the config lives

zsh is the one config that isn't a linked file. home-manager writes
`~/.config/zsh/.zshrc` from `nix/home/shell/zsh.nix` (`programs.zsh`), so edit
the Nix file and run `nrs`; editing `.zshrc` directly is overwritten.

Each topic module owns its own shell settings instead of one big zshrc:

| What | Where |
|---|---|
| History, options, `mkcd`/`extract`, navigation aliases, zellij auto-start | `nix/home/shell/zsh.nix` |
| Prompt | `nix/home/shell/starship.nix`, `configs/starship/starship.toml` |
| `ls`/`cat`/`grep`/`find` replacements, fzf settings | `nix/home/cli.nix` |
| git aliases, `git_current_branch` | `nix/home/git.nix` |
| `v`/`vim`, `EDITOR` | `nix/home/nvim.nix` |
| Toolchain `PATH`s, `proto activate` | `nix/home/dev/*.nix` |
| `nrs`, `ngc` (differ per **target OS**) | `nix/home/targets/` |

Aliases go in `home.shellAliases`, env vars in `home.sessionVariables`, `PATH`
entries in `home.sessionPath`, and anything else in
`programs.zsh.initContent`.

## Plugins

From Nix: [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete)
(loaded first, it runs `compinit` itself),
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
(loaded last).

## Per-machine settings and secrets

`~/.config/zsh/local_env.zsh` is sourced near the end of `.zshrc`, before
zellij starts. It's not in the repo: put secrets and per-machine `export`s
there, starting from `configs/zsh/local_env.zsh.sample`. See
[Secrets](/README.md#secrets).

## zellij auto-start

An interactive shell starts [zellij](zellij.md) unless any of these hold:
already inside zellij, connected over SSH, run as `zsh -ic '<command>'` (how
editors read your environment), no terminal attached, or `ZELLIJ_AUTOSTART=0`. Use
`ZELLIJ_AUTOSTART=0 zsh` for a one-off plain shell, or export it in
`local_env.zsh` to turn auto-start off on that machine.

## Files

| What | Path |
|---|---|
| Generated config | `~/.config/zsh/.zshrc` (`ZDOTDIR=~/.config/zsh`) |
| History | `~/.local/state/zsh/history` |
| Recent directories (zsh-autocomplete) | `~/.local/share/zsh/chpwd-recent-dirs` |
| Local settings | `~/.config/zsh/local_env.zsh` |
