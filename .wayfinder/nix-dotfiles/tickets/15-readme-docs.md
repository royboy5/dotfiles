---
title: README and docs restructure
type: grilling
status: closed
assignee: Roy Eng
blocked_by: [12, 13, 14]
---

## Question

What do the README and `docs/` look like after the port? Per-tool docs as in `~/.dotfiles/docs/`: which pages exist and what each must cover. Known needs: the zsh page covers zellij auto-start and its `ZELLIJ_AUTOSTART=0` opt-out; a dev-shell page covers `project`, direnv and `nus`, and how proto takes over inside pinned repos; a zellij/nvim page covers Ctrl-hjkl navigation across both and that Ctrl-l no longer clears shell panes (see [Seamless nvim–zellij navigation](10-nvim-zellij-navigation.md)).

## Resolution

Decided with the user on 2026-11-10.

**Split.** As in `~/.dotfiles`: the README is the manual for the whole repo, and `docs/` holds one page per tool for things that only matter while using that tool. The README links `GLOSSARY.md` from its layout section and uses its terms (**user layer**, **system layer**, **target OS**, **host**) in headings and wording.

**README sections.**
- **Install, per host**, in migration order: `wsl` (systemd required, manual Windows font step from [Which layer installs fonts](12-fonts.md)), `strike-freedom`, `unicorn-rx0` (commit `nixos/hardware/unicorn-rx0.nix` first), `qant-00` (reboot after the transient-root change). Each section lists its preconditions and the bootstrap command. It ends with **Adding a new host**: a flake output, a package list, and a `nixos/hardware/` file for NixOS hosts.
- **Layout**, including one line each for ghostty, git, starship and Hyprland (these get no `docs/` page).
- **Everyday use**: `nrs`, `nus`, `nfu`, `./bootstrap --dry`, `--clean-backups`.
- **Where does it go?**: carried over from `~/.dotfiles` "Adding things", rewritten around [Which layer owns each package](04-package-ownership.md). CLI tools go in the matching `home/*.nix` module. GUI apps, daemons and hardware tools go in the host's system layer (pacman/dnf list or `nixos/`). Fonts go in the system layer. Bazzite declares nothing.
- **Updating and rolling back**: `nfu` then `nrs`. Home-manager hosts roll back to a previous generation; `unicorn-rx0` boots an older entry or runs `nixos-rebuild --rollback`. No macOS content.
- **Reinstalling a host**: the permanent version of the fresh-install backup checklist from [Cutover and migration order](14-cutover.md): repos pushed, `~/.ssh`/`~/.gnupg`, secrets, zsh history, and restoring the existing keys. The one-off host order and branch/merge plan are not documented.
- **Secrets**: a few lines. `~/.config/zsh/local_env.zsh` is gitignored, holds exports only, and is restored from backup on a reinstall.
- **Troubleshooting**: cross-host problems only: a `before-nix` backup collision, GPU setup after a switch, WSL without systemd. Tool-specific fixes go on that tool's page.

**`nfu` alias** (ported from `~/.dotfiles`, already listed in [Bootstrap flow per target OS](05-bootstrap-flow.md)) = `nix flake update --flake ~/.dotfiles/nix`. It sits next to `nrs` in the shell module, works from any directory, and only updates the lock file (it does not switch).

**`docs/` pages**, each opening with the `[Home](/README.md) > X` breadcrumb:
- `nvim.md`: ported from `~/.dotfiles`, updated for this repo's base: Nix instead of Mason, `main`-branch treesitter, fidget, smart-splits. It links to `zellij.md` for navigation.
- `zellij.md`: modes, Ctrl-hjkl across nvim splits and zellij panes, and that Ctrl-l no longer clears shell panes ([Seamless nvim–zellij navigation](10-nvim-zellij-navigation.md)).
- `zsh.md`: `programs.zsh` (the one config that isn't linked), topic modules owning their aliases and env vars, `local_env.zsh`, zellij auto-start and `ZELLIJ_AUTOSTART=0`.
- `tmux.md`: short. Ported as-is, TPM setup (`prefix + I`).
- `dev-shells.md`: `project`, direnv, `nus`, available shells, adding a shell, how proto takes over inside pinned repos, and the nix-ld note for `unicorn-rx0`.

**Dropped from the old README:** the Ubuntu and macOS installs, the manual nerd-font steps (except the `wsl` Windows step), "Important directories", the Packer paths, "Helpful links" and the dead `configs/*/README.md` links. The shada and treesitter troubleshooting entries move to `nvim.md` only if they still apply after the port. Check this during implementation.

**When.** Written on the `nix` branch and finished before it merges to `master`. Each host's install section is written or corrected as that host migrates, so its steps are tested. `qant-00`'s section is written from the plan and fixed after it migrates from `master`.
