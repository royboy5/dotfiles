---
title: Which layer installs fonts
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Which fonts does this repo install, and which layer installs them on each host (`unicorn-rx0` NixOS, `wing-zero` Arch, `wsl` Fedora, Bazzite)? [Home-manager on non-NixOS distros](02-hm-on-non-nixos.md) found that Flatpaks can't see Nix-installed fonts, so decide whether GUI-facing fonts (terminal, bar, editor) come from Nix, the distro, or both, and what `wsl` needs given that Windows Terminal renders with Windows fonts.

## Resolution

**Rule:** fonts belong to the **system layer** because only GUI apps use them. Home-manager installs no fonts, and `fonts.fontconfig.enable` stays off. Distro-installed fonts are also visible to Flatpaks, which Nix fonts are not (see [Home-manager on non-NixOS distros](02-hm-on-non-nixos.md)).

**Families:** FiraCode Nerd Font and JetBrains Mono Nerd Font. Ghostty keeps `FiraCode Nerd Font Mono`. JetBrains Mono is installed so it's available, but no config names it. Hack is dropped. Another font, such as Symbols Nerd Font, is added only if [What goes in the Hyprland config](13-hyprland-config.md) needs one.

**Per host:**

| Host | Fonts |
|---|---|
| `unicorn-rx0` (NixOS) | `fonts.packages = [ pkgs.nerd-fonts.fira-code pkgs.nerd-fonts.jetbrains-mono ]` in `nixos/` |
| `wing-zero` (Arch) | `ttf-firacode-nerd` and `ttf-jetbrains-mono-nerd` (`[extra]`) in the pacman list |
| `wsl` (Fedora) | none. Windows Terminal uses fonts installed on Windows, so the docs say to install both fonts there by hand |
| Bazzite | none. Its system layer declares nothing |

The old manual Nerd Font steps in the README, and its link to the missing `scripts/install_firacode.sh`, go away in [README and docs restructure](15-readme-docs.md).
