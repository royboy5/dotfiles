---
title: Bootstrap flow per target OS
type: grilling
status: closed
assignee: reng
blocked_by: [01, 02, 03, 04]
---

## Question

What does `./bootstrap` do on each target OS (macOS, Arch, Fedora, Bazzite, NixOS) from a fresh install to an applied config? Cover: installing Nix, the system-layer package list format, applying home-manager, `nixos-rebuild` or `darwin-rebuild` (port `~/.dotfiles/bootstrap` for macOS), idempotency and dry-run, and the everyday rebuild alias (the counterpart of `ndr`).

Inputs: [Nix on Bazzite](01-nix-on-bazzite.md) leaves two things to settle here: does the Bazzite step survive a rebase (`initramfs-etc` tracking), and does Bazzite update through `bootc`?
Also settle which Bazzite installer to use: the two research tickets disagree (community installer vs Determinate `ostree` planner). Also check that the GPU setup (`sudo non-nixos-gpu-setup`) runs on non-NixOS hosts.

Also from [Flake layout and outputs](03-flake-layout.md): `wsl` needs a WSL-specific path (systemd may be off in WSL; check). `stargazer` installs Nix and nix-darwin from the 26.05 branches.

Also from [Which layer owns each package](04-package-ownership.md): Bazzite (`qant-00`) has an empty system-layer package list, so its bootstrap is just Nix enablement. `ujust` recipes may be called as bootstrap steps. `wsl`'s dnf list is `zsh` plus the Nix installer's prerequisites. Arch's pacman list is `zsh`, `ghostty`, `docker` (+ enabling the service), `reflector` and `wl-clipboard`.

## Resolution

**Scope change (2026-11-10):** `stargazer` and macOS are removed from this repo. The community installer has no x86_64-darwin build after 2.34.6, and the user chose to drop the Intel Mac rather than special-case it. There are four target OSes (Arch, Fedora, Bazzite, NixOS), and every host follows `nixpkgs-unstable`.

**Script**
- **One bash entrypoint.** `./bootstrap` dispatches on `hostname -s`, and `--host <name>` overrides it. An unknown host fails with the list of known hosts.
- **Flags:** `--dry`, `--host`, `--clean-backups`. The old `[OS] [PACKAGES...]` arguments, `--list`, `--no-update` and `--refresh-mirrors` are dropped.
- **Re-runnable.** Each step checks the machine's own state (is `/nix` there, is `nix` on PATH) and skips what's done. There is no state file. When a reboot or re-login is needed, the script stops with an instruction and expects a re-run.
- **`--dry`** prints every system-changing command without running it. On the Nix side it builds without activating (`nixos-rebuild build`, `home-manager build`).
- **Repo path.** The script refuses to run unless the repo is at `~/.dotfiles`, the path the `mkOutOfStoreSymlink` live links point at.
- **Two habits from `~/.dotfiles` on every host:**
  - refuse when `nix/*.nix` files are untracked by git
  - run `nix flake lock` as the user before any `sudo` step

**Backups**
- **First switch only.** `-b before-nix` is passed only on the first standalone home-manager switch, detected by `home-manager` not yet being on PATH. Passing it on every run would fail once a `.before-nix` file exists. NixOS sets `home-manager.backupFileExtension = "before-nix"`.
- **End of every run:** bootstrap lists the `*.before-nix` files under `~`, `~/.config` and `/etc`.
- **`./bootstrap --clean-backups`** deletes them after a y/N prompt.

**System layer**
- **Package lists are bash arrays** in the script.
- **Ensure only, no general upgrade.**
  - Arch: `pacman -Syu --needed <list>`. The `-u` is required because `-Sy` without it is a partial upgrade.
  - Fedora: `dnf install -y <list>`.
- **Arch extra steps:** enable `docker.service`, add `roy` to the `docker` group, enable `reflector.timer`. The timer replaces the old `--refresh-mirrors` flag.
- **Bazzite** has no list.

**Nix install**
- **The NixOS community installer on all three non-NixOS Linux hosts:** `curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install`. It settles the disagreement between the two research tickets.
  - **Reasons:** its ostree mode is the only one Bazzite can use, it uninstalls cleanly from its receipt, and it rolls back a failed install.
  - **Accepted cost:** it is labelled Beta.
- **Flakes.** Bootstrap makes sure `experimental-features = nix-command flakes` is in `/etc/nix/nix.conf` and restarts the daemon when it changed.

**Per host**

| Host | Flow |
|---|---|
| `unicorn-rx0` (Arch) | pacman list and extra steps → Nix → home-manager switch → GPU setup |
| `wsl` (Fedora) | Require systemd (`/run/systemd/system`). If it's missing, stop and print the `[boot] systemd=true` in `/etc/wsl.conf` + `wsl --shutdown` instruction (no `--init none` fallback). Then dnf list (`zsh` + installer prerequisites) → Nix → home-manager switch. No GPU setup. |
| `qant-00` (Bazzite) | Check or apply `root.transient = true` in `/etc/ostree/prepare-root.conf` and `rpm-ostree initramfs-etc --track`. If anything changed, stop for a reboot. Then `install ostree --persistence=/var/lib/nix` (pass it explicitly; the default is `/var/home/nix`) → home-manager switch → GPU setup. |
| `wing-zero` (NixOS) | Check the hostname → `nix-shell -p git` if git is missing → `sudo nixos-rebuild switch --flake ~/.dotfiles/nix#wing-zero` with flakes passed explicitly on the first run. If `nixos/hardware/wing-zero.nix` is missing, fail and point at `nixos-generate-config --show-hardware-config`. |

- **First home-manager switch:** `nix run home-manager/master -- switch -b before-nix --flake ~/.dotfiles/nix#roy@<host>`. Later runs use the installed `home-manager`.
- **GPU setup:** `sudo <absolute store path>/non-nixos-gpu-setup` after every switch on `unicorn-rx0` and `qant-00`. It is idempotent, and `sudo` doesn't see the user's PATH.
- **Bazzite after this change:**
  - The `initramfs-etc` tracking makes bootc refuse the deployment, so uupd falls back to `rpm-ostree` for updates. Accepted.
  - The `/nix` prerequisites are re-checked on every run. After any rebase or `bootc switch`, re-run `./bootstrap`.
  - Homebrew remains the documented fallback.

**Everyday commands**
- **`nrs`** (nix rebuild switch) runs `nixos-rebuild switch` on `wing-zero` and `home-manager switch` elsewhere, with the host taken from the host or target files. It touches only Nix.
- **`nfu`** (flake update) carries over unchanged.
- The system-layer lists are applied by re-running `./bootstrap`.

Facts came from a fact-finding subagent on 2026-11-09 (sources: the bazzite and uupd repos, rpm-ostree `origin.rs` and its man page, bootc `utils.rs`, the NixOS/nix-installer README, releases and `ostree.rs`, nixos.org/download, Fedora `wsl-setup`, the home-manager standalone docs and `check-link-targets.sh`, and the gpu module). Nothing was committed. Unconfirmed: whether the tracking survives `rpm-ostree rebase`, and whether the official Fedora WSL image ships `wsl-setup`.

## Amendment (2026-11-10, from [The NixOS host's system layer](09-wing-zero-system.md))

Hosts swap. The `unicorn-rx0` (Arch) row now applies to **`wing-zero`** (EndeavourOS, on the Arch path), with COSMIC, Hyprland and thermald added to its pacman list. The NixOS row now applies to **`unicorn-rx0`** (`nixos-rebuild switch --flake ~/.dotfiles/nix#unicorn-rx0`, failing if `nixos/hardware/unicorn-rx0.nix` is missing). GPU setup runs on `wing-zero` and `qant-00`. `nrs` runs `nixos-rebuild` on `unicorn-rx0`.
