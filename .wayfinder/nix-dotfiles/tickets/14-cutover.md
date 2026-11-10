---
title: Cutover and migration order
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

How does each host move from the current repo to the Nix port without losing state? Decide: the order hosts are migrated in, what is backed up first (`unicorn-rx0` goes from Arch to a fresh NixOS install; `strike-freedom` gets a fresh EndeavourOS install; `wsl` and Bazzite switch in place), and when `os/arch/` and the old bootstrap are retired from the repo.

## Resolution

Decided with the user on 2026-11-10.

**Branch.** The port is built on a long-lived `nix` branch. Its first commits delete `os/arch/`, the old `bootstrap` and `lib/helpers.sh`; the new `./bootstrap` replaces the old one at the same path. `master` keeps the bash setup as the rollback until the merge.

**Host order.** Each host must finish a clean `./bootstrap` and `nrs` before the next one starts.

1. **`wsl`** (in place): CLI-only and cheap to rebuild. Proves the user layer on generic Linux.
2. **`strike-freedom`** (fresh EndeavourOS, replacing its current NixOS): proves the pacman path, GPU setup and the GUI configs.
3. **`unicorn-rx0`** (fresh NixOS, replacing its current Arch): proves `nixos/` and home-manager as a NixOS module. Its `nixos/hardware/unicorn-rx0.nix` is pushed to `nix` from the machine.
4. **`qant-00`** (Bazzite, in place): last, because its Nix install is the riskiest.

**Repo path.** Each host gets a fresh clone at `~/.dotfiles` when it migrates. The old clone is removed, along with any `ln -sf` links it left behind, before the first switch.

**Backups before a fresh install** (`strike-freedom`, `unicorn-rx0`). Copy to external storage:
- every git repo under `~`, pushed, with a check for unpushed branches and stashes
- `~/.ssh` and `~/.gnupg`
- the secrets that will end up in `local_env.zsh`
- zsh history (`$XDG_STATE_HOME/zsh`)

After the install, the existing SSH keys are restored rather than regenerated, so the public keys in `nixos/` and on GitHub stay the same. Nothing from `strike-freedom`'s current `/etc/nixos` is kept.

**In-place hosts** (`wsl`, `qant-00`): no whole-system snapshot (`wsl --export` and ostree pinning were both declined). The safety nets are the `before-nix` file backups and the installer's uninstall receipt.

**Failure.** If a wiped host can't finish a clean bootstrap, fix forward on `nix`; don't reinstall the old OS. The host order pauses until that host passes.

**Merge.** `nix` merges to `master` with a merge commit once `unicorn-rx0` is done (no host needs the bash setup after that). `qant-00` then clones `master`. At the merge, delete the `nix` branch, `research/*`, and `origin/bash-only`, `origin/nvim-lua` and `origin/updated-ansible`. Local agent worktree branches are out of scope.
