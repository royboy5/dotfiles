---
title: Which layer owns each package
type: grilling
status: closed
assignee: reng
blocked_by: [01, 02, 03]
---

## Question

For each tool in `os/arch/` and `~/.dotfiles/nix/`, which layer installs it: Nix (user layer), the native package manager or Flatpak (system layer on Linux), or nix-darwin's Homebrew casks/brews (system layer on macOS)? Settle the rule first, then apply it, including GUI apps like ghostty, docker and VS Code on non-NixOS distros.

Inputs: [Home-manager on non-NixOS distros](02-hm-on-non-nixos.md) suggests a rule: Ghostty, and anything needing PAM, setuid or a system service, comes from the distro. NVIDIA hosts make Nix GUI apps fragile.
Also from [Flake layout and outputs](03-flake-layout.md): `wsl` (Fedora) is CLI-only, so it needs no GUI or Flatpak column. `stargazer` (Intel Mac) is on 26.05 and Homebrew Tier 3, so prefer casks that ship their own binaries.

## Resolution

**The rule.** By default, the Nix user layer installs every CLI tool on every host. The system layer owns anything that is:
- a GUI app (on non-NixOS Linux)
- something that needs PAM, setuid, a daemon or system service, or a kernel module
- tied to the session, display server or hardware (clipboard, drivers, WM)
- distro maintenance tooling

On NixOS the system layer is `nixos/`. On macOS it is Homebrew: casks for GUI apps, and brews only for the build toolchain that links against Homebrew libraries.

**Duplicates.** Where a distro also ships a tool (`git`, `curl`), the Nix copy comes first on PATH and the distro copy is left installed. zsh is the exception: the distro binary stays the login shell.

**Per host:**

| Host | System-layer route | System-layer packages |
|---|---|---|
| `unicorn-rx0` (Arch) | pacman (AUR only when unavoidable) | `zsh`, `ghostty`, `docker` + service, `reflector`, `wl-clipboard` (replaces `xclip`); `hyprland` waits on the Hyprland fog |
| `qant-00` (Bazzite) | Flatpak if a GUI app ever appears; `ujust` only as bootstrap recipes, never a package list | **none**: no Ghostty, no containers |
| `wsl` (Fedora) | dnf | `zsh` plus whatever the Nix installer needs that the image lacks. No GUI apps. No containers from this repo (use Docker Desktop's WSL integration from Windows, if at all) |
| `wing-zero` (NixOS) | nixpkgs in `nixos/` | `ghostty`; containers via `virtualisation.*` (decided in [The NixOS host's system layer](09-wing-zero-system.md)) |
| `stargazer` (macOS) | nix-homebrew | casks `brave-browser`, `google-chrome`, `google-drive`, `obsidian`, `rectangle`, `ghostty`, `docker-desktop`; brews `automake`, `cmake`, `ninja`, `pkgconf` |

**Containers:** the engine and the `docker` CLI are always system layer, never Nix, so client and daemon versions match.

**Dropped everywhere:** VS Code, Cursor, `claude-code`, `1password-cli`, `antigravity-cli`, `terraform` (and the `hashicorp` tap).

**Nix user layer, from `os/arch/`:** `eza`, `fd`, `fzf`, `git`, `httpie`, `jless`, `jq`, `k9s`, `neovim`, `ripgrep`, `starship`, `tmux`, `tree`, `zellij`. These join the `~/.dotfiles` `cli`/`git`/`nvim`/`terminal` package sets. Toolchains (`golang`, `rust`, `node`, `python`, `zig`) are left to [Language toolchains and dev shells](08-toolchains-devshells.md). Nerd fonts are left to the Fonts fog.

## Amendment (2026-11-10, from [Bootstrap flow per target OS](05-bootstrap-flow.md))

The `stargazer` row is void: macOS is no longer a target OS, so there's no nix-homebrew, cask list or brew list. Homebrew is the system layer nowhere. It survives only as Bazzite's documented fallback for Nix itself.

## Amendment (2026-11-10, from [The NixOS host's system layer](09-wing-zero-system.md))

The NixOS and Arch rows swap hosts. **`unicorn-rx0` is now NixOS:** its system layer is `nixos/`, with `ghostty`, Docker, COSMIC and Hyprland. **`wing-zero` (EndeavourOS) is now the Arch host:** its pacman list is the Arch list above plus COSMIC, Hyprland and thermald. Hyprland is no longer waiting on the fog: it's declared on both GUI hosts.

## Amendment (2026-11-10, from [Which layer installs fonts](12-fonts.md))

The system layer installs fonts too: FiraCode and JetBrains Mono Nerd Fonts go in `nixos/` on `unicorn-rx0` and in the pacman list on `wing-zero`. `wsl` and Bazzite install none.

## Amendment (2026-11-12)

Bitwarden's desktop app is a GUI app, so it's system layer on both GUI hosts: `bitwarden` in `wing-zero`'s pacman list, `bitwarden-desktop` in `nixos/` on `unicorn-rx0`. The Nix copy is newer than Arch's, but on Arch the distro package also brings the polkit policy and stable binary path that biometric unlock and the browser extension's native messaging depend on. The `bw` CLI isn't installed anywhere unless asked for (it would be Nix user layer).
