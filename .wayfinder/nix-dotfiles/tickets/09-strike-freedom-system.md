---
title: The NixOS host's system layer
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

What goes in `nixos/` for `strike-freedom`, the NixOS host (x86_64)? Decide:
- bootloader and hardware config: generate `hardware/strike-freedom.nix` from the live machine, or carry over the existing `/etc/nixos`
- GPU driver
- desktop or window manager (whether Hyprland is declared here; see the Hyprland fog on the map)
- system services (networking, audio, docker/podman, ssh)
- users (`roy`)
- nix settings (gc, optimise, flakes)

Start by reading the machine's current `/etc/nixos` config, if the user can share it.

From [Which layer owns each package](04-package-ownership.md): the container engine and the `docker` CLI come from the system layer (`virtualisation.*`), never home-manager. Ghostty comes from nixpkgs.

From [Zsh: Nix-declared or linked files](07-zsh-shape.md): zsh is the login shell, so the system layer needs `programs.zsh.enable = true` and `users.users.roy.shell = pkgs.zsh`. **nix-ld:** proto downloads unpatched vendor binaries (Node, Python, Go...) that can't run on NixOS without `programs.nix-ld.enable` (plus `programs.nix-ld.libraries` for anything missing). [Language toolchains and dev shells](08-toolchains-devshells.md) settled this: proto **does** download toolchains here (repos with `.prototools` pins), so nix-ld is **required**. What's left to decide is the `programs.nix-ld.libraries` set.

## Resolution

Decided with the user on 2026-11-10.

**Host swap.** The NixOS host is **`unicorn-rx0`** (Dell XPS 13 9370, Intel Kaby Lake, laptop). **`strike-freedom`** (Surface Pro 3) runs **EndeavourOS**, which counts as Arch: it goes through the pacman bootstrap path and `targets/generic-linux.nix`, and EndeavourOS isn't named anywhere in the repo. Hostnames stay with the hardware. Reasons:
- The Surface Pro 3 works fully on mainline (per the linux-surface feature matrix), but the nixos-hardware `microsoft-surface-pro-3` module pulls in linux-surface, a kernel built from source that takes hours on that CPU.
- NixOS rebuilds (evaluating the whole system and re-downloading changed closures) are heavy on weak hardware.
- Arch reuses an existing path, so it means less code in the repo.

**`nixos/` for `unicorn-rx0`**
- **Install:** fresh NixOS install with hostname `unicorn-rx0`. Commit the installer's `hardware-configuration.nix` as `nixos/hardware/unicorn-rx0.nix` and set `system.stateVersion` to the ISO's release (never changed after that). Push from the machine, then run `./bootstrap`. Nothing else from the installer's `/etc/nixos` is kept.
- **Hardware:** import `nixos-hardware.nixosModules.dell-xps-13-9370` (nixos-hardware becomes a flake input). It keeps the stock kernel and adds Kaby Lake CPU/GPU defaults, `mem_sleep_default=deep`, a `psmouse` blacklist, thermald and `throttled`. `hardware.graphics.enable`; no unfree GPU driver.
- **Power:** set `services.power-profiles-daemon.enable = true` explicitly. Otherwise nixos-hardware's `common/pc/laptop` turns on TLP and COSMIC turns on system76-power, and the daemons conflict. No TLP.
- **Firmware:** `services.fwupd` (Dell ships XPS firmware on LVFS).
- **Bootloader:** systemd-boot, `configurationLimit = 10`.
- **Desktop:** COSMIC (`services.desktopManager.cosmic`) and Hyprland (`programs.hyprland`) side by side, with `cosmic-greeter` choosing the session. *Verify during implementation:* the `xdg-desktop-portal` config picks the right backend per session (COSMIC sets its portal as the `mkDefault` config package).
- **Services:** NetworkManager; PipeWire with ALSA and Pulse plus rtkit; Bluetooth; `services.openssh` with password and root login off and `roy`'s public keys declared in `nixos/`; firewall on.
- **Containers:** `virtualisation.docker.enable`, with `roy` in `docker`. This matches the Arch path.
- **User:** `roy`, with `programs.zsh.enable` and `shell = pkgs.zsh` (NixOS's zsh is the login shell). Groups `wheel`, `networkmanager`, `docker`, `video`, `audio`. `mutableUsers` stays at its default; the password is set with `passwd` and no hash is in the repo.
- **Nix:** port the `~/.dotfiles` nix-darwin block (flakes, weekly gc `--delete-older-than 30d`, `nix.optimise.automatic`, an `allowUnfreePredicate` allowlist that starts empty). home-manager runs as a NixOS module with `useGlobalPkgs` and `useUserPackages`.
- **nix-ld:** `programs.nix-ld.enable` with the default libraries. Add libraries only when a proto-downloaded binary fails.

**`strike-freedom` (EndeavourOS / Arch path):** mainline kernel, no linux-surface. The pacman list gains COSMIC, Hyprland and thermald on top of the Arch list from [Which layer owns each package](04-package-ownership.md). No TLP; the power daemon is whatever COSMIC's packages bring (confirm during implementation).

**Hyprland config** is a `linkConfig` link (`configs/hypr/`) on the GUI hosts `unicorn-rx0` and `strike-freedom` only, like ghostty. Its contents stay in the map's Hyprland fog.

Sources (fetched 2026-11-10): the nixos-hardware `flake.nix`, `microsoft/surface-pro/3`, `surface/surface-pro-intel`, `dell/xps/13-9370` and `common/pc/laptop`; nixpkgs `nixos/modules/services/desktop-managers/cosmic.nix`; and the linux-surface README and supported-devices matrix.
