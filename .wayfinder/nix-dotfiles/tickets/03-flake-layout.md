---
title: Flake layout and outputs
type: grilling
status: closed
assignee: reng
blocked_by: []
---

## Question

What is the flake's shape? Decide: outputs (`homeConfigurations` per host vs per OS, `nixosConfigurations` for the NixOS machine, `darwinConfigurations` for macOS), how hosts are named (collect the real machines' hostnames; the macOS host is a personal Mac, not the work Mac), how the module tree from `~/.dotfiles/nix/home/` is ported (which modules carry over, minus work-only ones), and where per-host or per-OS differences live. Also decide whether `linkConfig` live links carry over.

## Resolution

**Hosts.** Every host uses username `roy` and is x86_64.

| Host | Target OS | Output |
|---|---|---|
| `wing-zero` | NixOS | `nixosConfigurations.wing-zero` (home-manager as a NixOS module) |
| `unicorn-rx0` | Arch | `homeConfigurations."roy@unicorn-rx0"` |
| `qant-00` | Bazzite | `homeConfigurations."roy@qant-00"` |
| `wsl` | Fedora, running under WSL | `homeConfigurations."roy@wsl"` |
| `stargazer` | macOS, Intel | `darwinConfigurations.stargazer` (home-manager as a darwin module) |

**Decisions:**
- **One output per host,** keyed by hostname. home-manager's `user@host` key lets `home-manager switch --flake` pick the config automatically.
- **The flake lives in `nix/flake.nix`,** matching `~/.dotfiles`. Commands take `~/.dotfiles/nix#<host>`, hidden behind aliases.
- **Tree:**
  ```
  nix/
    flake.nix          # inputs + one output per host
    hosts/<host>.nix   # per machine: picks a target, plus small host overrides
    home/              # shared user layer, ported from ~/.dotfiles/nix/home
      targets/
        darwin.nix          # macOS-only user bits (Homebrew shellenv etc.)
        generic-linux.nix   # targets.genericLinux + GPU, for Arch/Fedora/Bazzite
    darwin/            # nix-darwin system layer (+ homebrew.nix)
    nixos/             # NixOS system layer
      hardware/<host>.nix
  ```
  Shared `home/` modules avoid `isDarwin`/`isLinux` conditionals where possible.
- **Modules ported:** `shell`, `cli`, `git`, `terminal`, `nvim`, `dev`. **Left out:** `cloud` (work-only), `vscode`, `cursor`. Each can come back as a single file.
- **`linkConfig` carries over** as `mkOutOfStoreSymlink`, with the repo path defined once (default `~/.dotfiles`) rather than hardcoded.
- **nixpkgs:** every host follows `nixpkgs-unstable` except `stargazer`.
- **`stargazer` is a sunset host.** nixpkgs-unstable no longer evaluates on x86_64-darwin, and 26.05 is the last release that supports it (end of life 2026-12-31). Homebrew put Intel Macs on Tier 3 in September 2026 and stops running on them on 2027-09-01.
  - `stargazer` pins its own inputs: `nixpkgs-26.05-darwin`, `nix-darwin-26.05` and the matching home-manager branch.
  - Its host file marks it as sunset.
  - The `darwin/` layer is written generically, for a future Apple Silicon Mac.
  - Consequence: shared `home/` modules must evaluate against both unstable and 26.05.
- **`wsl` (Fedora under WSL) is CLI-only.** It uses the generic-linux target with the GPU module off, and has no GUI apps.

Sources for the Intel facts: the NixOS 26.05 announcement, the nixpkgs unstable release notes, the nix-darwin README and the Homebrew 7.0.0 post (fetched 2026-11-09 by a fact-finding subagent; nothing was committed).

## Amendment (2026-11-10, from [Bootstrap flow per target OS](05-bootstrap-flow.md))

`stargazer` is removed, along with macOS as a target OS. That drops `darwinConfigurations`, `darwin/` and `home/targets/darwin.nix`, as well as the 26.05 pin. Every host follows `nixpkgs-unstable`, so shared `home/` modules only need to evaluate against unstable.

## Amendment (2026-11-10, from [The NixOS host's system layer](09-wing-zero-system.md))

`unicorn-rx0` and `wing-zero` swap roles. **`unicorn-rx0`** (Dell XPS 13 9370) is the NixOS host: `nixosConfigurations.unicorn-rx0`, with `nixos/hardware/unicorn-rx0.nix`. **`wing-zero`** (Surface Pro 3, EndeavourOS, which counts as Arch) is `homeConfigurations."roy@wing-zero"` on `targets/generic-linux.nix`. `nixos-hardware` joins the flake inputs.
