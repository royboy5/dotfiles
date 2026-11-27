---
title: Home-manager on non-NixOS distros
type: research
status: closed
assignee: research-agent
blocked_by: []
---

## Question

What breaks or needs special handling when standalone home-manager manages the user layer on Arch and Fedora? Cover: GUI/OpenGL/Vulkan apps from nixpkgs (nixGL, `targets.genericLinux`), fonts visible to native apps, making a Nix-installed zsh the login shell (`/etc/shells`, chsh), locale/`LOCALE_ARCHIVE`, systemd user services, and XDG data dirs/desktop entries. Note anything that differs on Bazzite.

## Resolution

Findings: `research/hm-on-non-nixos.md` on local branch `research/hm-on-non-nixos` (commit `628eaa9`, not pushed). Covers home-manager 26.05 stable and 26.11 dev.

- **Every non-NixOS host:** `targets.genericLinux.enable = true`. It sets the XDG/terminfo/cursor paths and distro zsh completions, and from 25.11 turns on the GPU module.
- **GL/Vulkan apps:** `targets.genericLinux.gpu` (run `sudo non-nixos-gpu-setup` once, then again when warned). nixGL is only the no-root fallback. **NVIDIA is fragile:** the Nix driver must match the host driver exactly.
- **Ghostty:** install it natively (Arch `[extra]`, Fedora COPR/Terra) and let home-manager manage only the config. On Bazzite, nixpkgs Ghostty plus the GPU module is fine on AMD/Intel but not NVIDIA.
- **Login shell:** keep `/usr/bin/zsh`. Don't chsh to a Nix zsh.
- **Fonts:** `fonts.fontconfig.enable` reaches native apps but not Flatpaks. Flatpak-facing fonts must be native or real files in `~/.local/share/fonts`.
- **Locale/session:** mostly automatic. Log out and back in after the first switch. User services restart on switch.
- **Rule of thumb:** anything needing PAM, setuid or a system service comes from the distro.
- **Unverified:** whether `flatpak override --filesystem=/nix/store:ro` works for fonts; whether Flatpak desktop entries survive the changed `XDG_DATA_DIRS`; whether `programs.ghostty.package = null` works on every release.
- **Conflict with [Nix on Bazzite](01-nix-on-bazzite.md):** this ticket names the Determinate ostree planner. That ticket recommends the NixOS community installer, whose ostree code is the same, because Determinate now defaults to Determinate Nix. Settle it in Bootstrap flow per target OS.
