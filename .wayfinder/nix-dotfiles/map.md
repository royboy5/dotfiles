---
title: Port this repo to Nix, modelled on ~/.dotfiles
type: map
---

## Destination

A decided spec for rebuilding this repo on Nix + home-manager, modelled on `~/.dotfiles`, for the four **target OSes**: Arch, Fedora, Bazzite, NixOS. The spec covers the target layout, module list, per-OS bootstrap flow and migration order, and is ready to hand to an implementation session.

## Notes

- Domain: personal dotfiles. Vocabulary is in `GLOSSARY.md` (**user layer**, **system layer**, **target OS**).
- Reference repo: `~/.dotfiles` (work, macOS, nix-darwin + home-manager, `linkConfig` live links, direnv dev shells). Read its `README.md` and `nix/` before deciding layout questions.
- Shape decided while charting: **hybrid**. Nix/home-manager owns the user layer everywhere. A thin bash bootstrap handles the system layer on Arch, Fedora and Bazzite (a declared package list per distro). NixOS gets a full `nixosConfigurations` host with home-manager as a NixOS module.
- One host per target OS exists today (see [Flake layout and outputs](tickets/03-flake-layout.md)). Fedora runs under WSL. NixOS is `unicorn-rx0` (Dell XPS 13 9370), and `strike-freedom` (Surface Pro 3) runs EndeavourOS on the Arch path (see [The NixOS host's system layer](tickets/09-strike-freedom-system.md)). macOS was re-added on 2026-11-09 for the Intel Mac `stargazer`, then **removed again on 2026-11-10** (see [Bootstrap flow per target OS](tickets/05-bootstrap-flow.md)).
- This repo stays **independent** of `~/.dotfiles`: a one-time port, no shared base.
- Work-only content stays out: `gke-creds`, `cloud.nix` and its fp-ev clusters, `shells/envs/ma.nix`, internal package registry vars, the tmux k8s status segment.
- Configs: `~/.dotfiles` versions are the starting baseline, but this repo's current configs must be weighed too. **During implementation, ask the user for confirmation before adopting any specific config.**
- Skills: `grilling` + `domain-modeling` for grilling tickets. `research` for research tickets.

## Decisions so far

- [Nix on Bazzite](tickets/01-nix-on-bazzite.md): feasible but unsupported. Needs a one-time transient-root change and the community installer's ostree mode. Homebrew is the fallback.
- [Home-manager on non-NixOS distros](tickets/02-hm-on-non-nixos.md): use `genericLinux` plus its GPU module. Keep the system zsh as the login shell. Ghostty and anything needing PAM or setuid come from the distro. Flatpaks can't see Nix fonts.
- [Flake layout and outputs](tickets/03-flake-layout.md): `nix/flake.nix` with one output per host for four hosts. Shared `home/` plus `home/targets/` and `nixos/`. Everything is on unstable. Fedora is the CLI-only `wsl` host. (Amended: `stargazer` and `darwin/` were removed. `unicorn-rx0` is now the NixOS host and `strike-freedom` the Arch host.)
- [Which layer owns each package](tickets/04-package-ownership.md): Nix owns every CLI tool. The system layer owns GUI apps, daemons/setuid, session/hardware tools and distro tooling (pacman, dnf, Flatpak, `nixos/`). Bazzite declares nothing. VS Code, Cursor and the vendor CLIs are dropped everywhere.
- [Bootstrap flow per target OS](tickets/05-bootstrap-flow.md): one re-runnable bash `./bootstrap` keyed by hostname, with `--dry`, `--host` and `--clean-backups`. It installs Nix with the NixOS community installer on all Linux hosts, and turns on flakes. Each host gets its own path (Bazzite: transient root, then reboot, then ostree mode; WSL requires systemd). The everyday rebuild is `nrs`. Also removed `stargazer`/macOS.
- [Reconcile drifted configs](tickets/06-reconcile-configs.md): every config stays a `linkConfig` link. git and starship come from `~/.dotfiles`, minus the work bits. The global git ignore holds only `.direnv/` and `.envrc`. tmux is ported as-is on TPM. zellij gets the short `~/.dotfiles` file without the Ctrl-hjkl/Ctrl-m binds. nvim keeps this repo's base plus `main`-branch treesitter and fidget, and Nix replaces Mason. ghostty is set to storm with no super binds and is linked on GUI hosts only.
- [Zsh: Nix-declared or linked files](tickets/07-zsh-shape.md): zsh is declared with home-manager's `programs.zsh`, the one exception to linked configs. Plugins come from Nix. History keeps this repo's XDG settings at 10000. Zellij auto-starts everywhere unless `ZELLIJ_AUTOSTART=0`. Each topic module owns its own aliases and env vars. Secrets go in one gitignored `local_env.zsh`, not sops/agenix.
- [Language toolchains and dev shells](tickets/08-toolchains-devshells.md): ported `nix/shells`, direnv and `project`. Global go/gopls, rustup, zig/zls, uv/ruff, node/pnpm from Nix. opencode, Flutter, the Android SDK and Volta are dropped. `proto` comes from Nix with `activate`, so pinned repos match non-Nix teammates. That means the NixOS host (now `unicorn-rx0`) needs nix-ld.
- [Can proto/moon use toolchains already on PATH](tickets/11-proto-system-toolchains.md): proto uses the PATH tool only when nothing is pinned; a pinned version errors or downloads. moon v2 can skip proto and use PATH tools (`MOON_TOOLCHAIN_FORCE_GLOBALS`, or toolchains with no version plus `versionFromPrototools: false`), with no version check. proto's Node/Python downloads would need nix-ld on NixOS.
- [The NixOS host's system layer](tickets/09-strike-freedom-system.md): hosts swapped. `unicorn-rx0` (XPS 13 9370) is NixOS, with the nixos-hardware 9370 module, systemd-boot and COSMIC + Hyprland behind cosmic-greeter. It sets power-profiles-daemon explicitly so TLP and system76-power stay off. It also gets fwupd, Docker, NetworkManager/PipeWire/Bluetooth, key-only ssh and nix-ld. `strike-freedom` (Surface Pro 3) runs EndeavourOS, which counts as Arch, on a mainline kernel with no linux-surface.
- [Which layer installs fonts](tickets/12-fonts.md): the system layer installs fonts and home-manager installs none. FiraCode and JetBrains Mono Nerd Fonts go in `nixos/` and the pacman list. Ghostty stays on FiraCode. `wsl` and Bazzite install none, and the docs give the manual Windows step for `wsl`.
- [What goes in the Hyprland config](tickets/13-hyprland-config.md): Hyprland stays stock. Only the package is installed, with no bar, launcher or other helpers. Its default `hyprland.conf` is copied once into `configs/hypr/` with the terminal changed from kitty to ghostty, and `linkConfig` links it on the GUI hosts.
- [Seamless nvim–zellij navigation](tickets/10-nvim-zellij-navigation.md): vim-zellij-navigator 0.3.0 (zellij, `move_focus`, stops at the edge) plus smart-splits.nvim v3 with backend-zellij-lua. Ctrl-hjkl crosses nvim splits and zellij panes. Shell panes lose Ctrl-l clear. Testing in Ghostty and Windows Terminal moves to implementation.
- [Cutover and migration order](tickets/14-cutover.md): build on a `nix` branch with the old setup deleted from the start. Migrate `wsl` → `strike-freedom` → `unicorn-rx0` → `qant-00`, each host passing before the next. Fresh clone at `~/.dotfiles`. Fresh installs back up repos, ssh/gpg keys, secrets and history, and restore the existing keys; in-place hosts get no snapshot. Fix forward on failure. Merge to `master` after `unicorn-rx0`, then delete the stale branches.
- [README and docs restructure](tickets/15-readme-docs.md): the README is the manual. It has per-host install sections in migration order, plus "Adding a new host", layout (linking `GLOSSARY.md`), everyday use, "Where does it go?" by layer, update/rollback, reinstall backups, secrets and cross-host troubleshooting. `docs/` has nvim, zellij, zsh, tmux and dev-shells pages. The old README content is dropped. `nfu` (ported) documented for `nix flake update`. Written on `nix` as each host migrates.

## Not yet specified

<!-- empty: every ticket is closed; the spec is ready to hand to implementation -->

## Out of scope

- A shared base consumed by both this repo and `~/.dotfiles`: would be a separate effort.
- Work-only tooling (see Notes).
- macOS (`stargazer`, nix-darwin, Homebrew casks): removed 2026-11-10 because the Nix installer chosen in [Bootstrap flow per target OS](tickets/05-bootstrap-flow.md) has no Intel Mac build. A future Apple Silicon Mac would be a fresh effort modelled on `~/.dotfiles`.
