---
title: What goes in the Hyprland config
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Hyprland is declared on both GUI hosts (`unicorn-rx0`, `strike-freedom`) with its config linked from `configs/hypr/`. What goes in it: keybinds, bar, launcher, notifications, lock/idle, wallpaper, and how much ricing? Which of those pieces are packages, and which layer installs them on each host (per [Which layer owns each package](04-package-ownership.md))?

## Resolution

**Stock Hyprland. No ricing.** The user wants the session to stay as it is after a fresh install, so nothing gets designed for it now.

- **Packages:** only Hyprland: `programs.hyprland` in `nixos/` on `unicorn-rx0`, and `hyprland` in the pacman list on `strike-freedom`. No bar, launcher, notification daemon, lock, idle, wallpaper, screenshot or clipboard tools. Kitty isn't installed. The default config's wofi and dolphin binds are left as they are, pointing at apps that aren't installed.
- **Config:** take Hyprland's default `hyprland.conf` (the example config that ships in the package, `share/hypr/hyprland.conf`) and copy it **once** into `configs/hypr/hyprland.conf`. Change only `$terminal = kitty` to `$terminal = ghostty`, so SUPER+Q opens Ghostty. Commit it and link it with `linkConfig` on the GUI hosts only, like ghostty. This matches [The NixOS host's system layer](09-strike-freedom-system.md). We chose this over having Nix generate the file from the package: a live link can be edited in place like the other configs, and following upstream's defaults matters less once the file starts being customised.
- **Fonts:** this ticket needs no extra font, so Symbols Nerd Font is not added (see [Which layer installs fonts](12-fonts.md)).
- **Later:** choosing a bar, launcher, notifications, lock/idle, wallpaper and theme is left for whenever the user wants to rice the session. It isn't part of this spec.
