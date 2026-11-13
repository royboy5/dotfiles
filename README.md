# Dotfiles

Personal machine setup for Linux, built on [Nix](https://nixos.org) and
[home-manager](https://github.com/nix-community/home-manager). One repo sets up
every **host**. The **user layer** (CLI tools, shell, editor, git, terminal
multiplexers and their configs) is identical everywhere. The **system layer**
(native packages, desktop, drivers, services, GUI apps) differs per **target
OS**. Terms are defined in [GLOSSARY.md](GLOSSARY.md).

| Host | Target OS | Status |
|---|---|---|
| `wsl` | Fedora under WSL (CLI only) | migrated |
| `wing-zero` | Arch (EndeavourOS), Surface Pro 3 | being migrated |
| `unicorn-rx0` | NixOS, Dell XPS 13 9370 | planned |
| `qant-00` | Bazzite | planned |

## Table of contents

- [Install](#install)
  - [wsl](#wsl)
  - [wing-zero](#wing-zero)
  - [Adding a new host](#adding-a-new-host)
- [Layout](#layout)
- [Everyday use](#everyday-use)
- [Where does it go?](#where-does-it-go)
- [Updating and rolling back](#updating-and-rolling-back)
- [Reinstalling a host](#reinstalling-a-host)
- [Secrets](#secrets)
- [Troubleshooting](#troubleshooting)

## Install

Every host follows the same shape: clone to `~/.dotfiles` (the only path
bootstrap accepts, because the config links point there), then run
`./bootstrap`. It works out the host from `hostname -s` (override with
`--host <name>`), installs the system-layer packages and Nix, then applies
the config. It's safe to re-run: finished steps are skipped. When it needs
a reboot or a restart it stops and says so; run it again afterwards.

Run it as `roy`, not with `sudo` (it asks for sudo itself). Preview with
`./bootstrap --dry`.

### wsl

Fedora under WSL, CLI only.

1. **If an older clone of this repo is there,** save what lives only inside it,
   then remove the links it made and the clone. The old setup kept secrets in
   `configs/zsh/local_env*.zsh` inside the clone, so copy them out first, and
   check for unpushed work:
   ```bash
   for f in ~/.dotfiles/configs/zsh/local_env*.zsh; do
     [ -e "$f" ] && cp "$f" ~/"$(basename "$f").old"
   done
   git -C ~/.dotfiles status --short
   git -C ~/.dotfiles log --branches --not --remotes --oneline   # unpushed commits
   ```
   Then check the list of links before deleting:
   ```bash
   find ~ -maxdepth 3 -type l -lname '*/.dotfiles/*' -print
   find ~ -maxdepth 3 -type l -lname '*/.dotfiles/*' -delete
   rm -rf ~/.dotfiles
   # nvim plugins and tools the old config installed; reinstalled on first start
   rm -rf ~/.local/share/nvim/lazy ~/.local/share/nvim/mason
   ```
2. **Turn on systemd and set the hostname.** The Nix daemon is a systemd
   service, and bootstrap picks the host by name. Add to `/etc/wsl.conf`
   (with `sudo`, keeping anything already there):
   ```ini
   [boot]
   systemd=true

   [network]
   hostname=wsl
   ```
   Then run `wsl --shutdown` from PowerShell and reopen WSL. Check with
   `hostname -s` (prints `wsl`) and `ls -d /run/systemd/system`.
3. **Clone and bootstrap:**
   ```bash
   # -b nix until the Nix port is merged to master
   git clone -b nix https://github.com/royboy5/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./bootstrap --dry   # preview
   ./bootstrap
   ```
   It installs zsh with dnf and makes it your login shell, installs Nix,
   applies home-manager, clones TPM and sets up rustup. Existing files that
   home-manager would replace are moved aside as `*.before-nix` and listed at
   the end.
4. **Fonts (on Windows).** Windows Terminal draws with Windows fonts, so
   install [FiraCode Nerd Font and JetBrains Mono Nerd Font](https://www.nerdfonts.com/font-downloads)
   on Windows (select the `.ttf` files → right-click → **Install**) and set
   Windows Terminal's font for the WSL profile to `FiraCode Nerd Font Mono`.
5. **Restore your secrets** (if step 1 saved any): copy the `export` lines from
   `~/local_env*.zsh.old` into `~/.config/zsh/local_env.zsh` (see
   [Secrets](#secrets)), then delete the `.old` files.
6. **Open a new terminal tab.** zellij starts automatically. In tmux, press
   `prefix + I` (prefix is Ctrl-Space) once to install its plugins.

### wing-zero

Surface Pro 3 on EndeavourOS (the Arch path), a GUI host with COSMIC and
Hyprland side by side.

1. **Before wiping:** follow [Reinstalling a host](#reinstalling-a-host).
2. **Install EndeavourOS.** Any desktop option is fine; bootstrap adds COSMIC
   and Hyprland either way. In the installer, set the hostname to `wing-zero`
   (or pass `--host wing-zero` to bootstrap later) and create the user `roy`.
3. **Restore `~/.ssh`** from the backup (`chmod 700 ~/.ssh; chmod 600 ~/.ssh/id_*`
   for the private keys), then clone and bootstrap:
   ```bash
   # -b nix until the Nix port is merged to master
   git clone -b nix git@github.com:royboy5/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./bootstrap --dry   # preview
   ./bootstrap
   ```
   It:
   - installs with pacman: `zsh ghostty bitwarden docker reflector wl-clipboard
     cosmic hyprland thermald iio-sensor-proxy ttf-firacode-nerd
     ttf-jetbrains-mono-nerd` (`cosmic` is the whole COSMIC group;
     `iio-sensor-proxy` reads the accelerometer for auto-rotate). This also upgrades the system
     (`pacman -Syu`).
   - enables `docker.service`, `reflector.timer` (weekly mirror refresh) and
     `thermald.service`, and adds you to the `docker` group
   - makes zsh your login shell
   - turns off the graphics driver's Panel Self Refresh (`i915.enable_psr=0`
     in the kernel options), without which the Surface Pro 3 freezes when
     COSMIC or Hyprland starts. It edits `/etc/kernel/cmdline` and runs
     `reinstall-kernels` (systemd-boot), or edits `/etc/default/grub` and runs
     `grub-mkconfig` (GRUB)
   - installs Nix and applies home-manager, which links the ghostty and
     Hyprland configs
   - runs the GPU setup, so Nix apps can use the GPU
   - clones TPM and sets up rustup
4. **Reboot** for the kernel option, the docker group, the login shell and
   the new session variables (only the kernel option needs a full reboot;
   logging out and back in covers the rest). Until then, new terminals still start bash
   with none of the config, because the session that opened them read the old
   login shell. Pick COSMIC or Hyprland at the login screen. In Hyprland,
   SUPER+Q opens Ghostty and SUPER+M exits. The screen turns with the
   Surface in both desktops (`auto-rotate`, below).
5. **Restore your secrets** into `~/.config/zsh/local_env.zsh` (see
   [Secrets](#secrets)) and zsh history into `~/.local/state/zsh/`.
6. **Open Ghostty.** zellij starts automatically. In tmux, press
   `prefix + I` (prefix is Ctrl-Space) once to install its plugins.

### Adding a new host

1. `nix/flake.nix`: add an output. Non-NixOS: `homeConfigurations."roy@<host>" = mkHome "<host>";`.
2. `nix/hosts/<host>.nix`: import its target (`../home/targets/generic-linux.nix`
   on non-NixOS) plus any host overrides.
3. `lib/hosts/<host>.sh`: a `host_<host>` function with the system-layer
   package list and steps (see `lib/hosts/wsl.sh`), and add the host to
   `KNOWN_HOSTS` in `./bootstrap`. A hyphen in the host name becomes an
   underscore in the function name: `wing-zero` → `host_wing_zero`.
   A GUI host also imports `../home/gui.nix` in step 2.
4. `git add` the new files (flakes only see tracked files), then bootstrap.

## Layout

```
bootstrap                 # entrypoint: ./bootstrap [--dry] [--host <name>] [--clean-backups]
lib/
  utils.sh                # logging and the --dry wrapper
  common.sh               # steps shared by every host (Nix, flakes, home-manager, backups)
  hosts/<host>.sh         # one per host: its system-layer packages and steps
nix/
  flake.nix               # one output per host
  hosts/<host>.nix        # picks a target, plus host overrides
  home/                   # the user layer, one module per topic
    default.nix           #   imports everything; defines linkConfig
    shell/                #   zsh (declared) and starship
    cli.nix  git.nix  terminal.nix  nvim.nix
    gui.nix               #   GUI hosts only: ghostty and Hyprland config links
    auto-rotate.nix       #   tablets only (wing-zero): auto-rotate and its COSMIC autostart
    scripts/              #   shell scripts packaged by the modules (project, auto-rotate)
    dev/                  #   language toolchains, direnv, project, proto
    targets/generic-linux.nix   # non-NixOS: targets.genericLinux, nrs, ngc, ~/.config/home-manager link
  shells/                 # project dev shells (own flake.lock), see `project`
configs/                  # config files, linked live into ~/.config
tests/                    # eval.sh (Nix checks), bootstrap.bats, auto-rotate.bats
```

**Configs are live links.** `linkConfig "<app>"` in a module links
`configs/<app>` into place with a link to the repo, not a copy in the Nix
store, so editing a file under `configs/` takes effect immediately, with no
rebuild. The exception is zsh, which home-manager writes from
`nix/home/shell/zsh.nix`.

- **git:** `configs/git/config` (delta as the pager) and `configs/git/ignore`
  (global ignores: `.direnv/`, `.envrc`).
- **starship:** `configs/starship/starship.toml`. Shows the active dev shell
  as `[❄ <name>]`.
- **ghostty:** `configs/ghostty/config`, GUI hosts only. Tokyo Night Storm,
  FiraCode Nerd Font Mono.
- **Hyprland:** `configs/hypr/hyprland.lua`, GUI hosts only. Hyprland's stock
  example config with ghostty as the terminal (SUPER+Q). Its launcher and
  file-manager binds point at apps that aren't installed. It starts
  `auto-rotate` where it's installed.
- **auto-rotate** (wing-zero): `nix/home/scripts/auto-rotate.sh` follows the
  accelerometer (`monitor-sensor`, from `iio-sensor-proxy`) and turns the
  built-in screen: with `hyprctl` in Hyprland, which also turns touch and pen
  input, and with `cosmic-randr` in COSMIC, which turns them by itself.
  Hyprland starts it from `hyprland.lua`, COSMIC from
  `~/.config/autostart/auto-rotate.desktop`. Defaults to the Surface Pro 3's
  panel (`eDP-1`, 2160x1440); set `AUTO_ROTATE_OUTPUT` / `AUTO_ROTATE_MODE` to
  change them. If the screen turns the wrong way, the mapping is
  `quarter_turns` in the script.

Per-tool pages, for things that only matter while using that tool:
[Neovim](docs/nvim.md), [Zellij](docs/zellij.md), [Zsh](docs/zsh.md),
[Tmux](docs/tmux.md), [Dev shells](docs/dev-shells.md).

## Everyday use

| Command | What it does |
|---|---|
| `nrs` | Apply the config after editing `nix/` (home-manager switch for this host). |
| `nfu` | Update `nix/flake.lock` (all packages) to the latest nixpkgs. Apply with `nrs`. |
| `nus` | Update the dev shells' lock (`nix/shells/flake.lock`). |
| `ngc` | Delete all old generations and free their space (no rollback afterwards). |
| `home-manager news`, `home-manager generations` | Plain `home-manager` commands find this repo through `~/.config/home-manager` (a link to `nix/`) and pick `roy@<hostname>`. |
| `./bootstrap` | Re-apply the system layer (package lists) as well as Nix. |
| `./bootstrap --dry` | Show what bootstrap would change; builds without activating. |
| `./bootstrap --clean-backups` | Delete the `*.before-nix` files from the first switch. |
| `dot` | `cd ~/.dotfiles` |

## Where does it go?

| You want… | Put it in |
|---|---|
| A CLI tool | the matching `nix/home/*.nix` module (`cli.nix`, `git.nix`, `dev/…`), as `home.packages`. |
| Its aliases, env vars, `PATH` entries | the same module: `home.shellAliases`, `home.sessionVariables`, `home.sessionPath`. |
| A config file | `configs/<app>/…`, linked with `linkConfig` from that module. |
| A shell function or zsh option | `nix/home/shell/zsh.nix` (or the topic module's `programs.zsh.initContent`). |
| A GUI app, a daemon or system service, anything needing setuid/PAM, a driver or hardware tool, a font | the **system layer** of the host: its package list in `lib/hosts/<host>.sh`. Bazzite declares nothing. |
| A config only GUI hosts use | `configs/<app>/`, linked from `nix/home/gui.nix`. |
| Something only one host needs | `nix/hosts/<host>.nix`. |

Commit (or at least `git add`) new `nix/` files before `nrs`; flakes ignore
untracked files.

## Updating and rolling back

```bash
nfu   # update the lock file
nrs   # build and switch
```

If something breaks, go back to the previous generation:

```bash
home-manager generations              # newest first
/nix/store/<hash>-home-manager-generation/activate   # path from the list
```

or `git checkout` the previous `nix/flake.lock` and run `nrs`. `ngc` deletes
every old generation, so there is nothing to roll back to after it.

**A package fails to build after `nfu`** (a long compile, then an error): it's
usually broken in nixpkgs at that commit, so the binary cache has no copy and
building it yourself fails the same way. Check
`https://hydra.nixos.org/job/nixpkgs/unstable/<package>.x86_64-linux`. Go
back with `git checkout HEAD~1 -- nix/flake.lock` (or `git revert` the update
commit), run `nrs`, and try `nfu` again in a few days.

## Reinstalling a host

Before wiping a machine, copy these to external storage:

- every git repo under `~`, pushed: check for unpushed branches and stashes
- `~/.ssh` and `~/.gnupg`
- `~/.config/zsh/local_env.zsh` (see [Secrets](#secrets))
- zsh history: `~/.local/state/zsh/`

After the fresh install, restore `~/.ssh` (keep the existing keys rather than
generating new ones, so GitHub and the hosts that trust them keep working),
then follow the host's [Install](#install) section.

## Secrets

Secrets and per-machine settings go in `~/.config/zsh/local_env.zsh`: plain
`export` lines, sourced at the end of `.zshrc`. It's not in the repo and never
goes in Nix (the Nix store is world-readable). Start from
`configs/zsh/local_env.zsh.sample`. Restore it from your backup when
reinstalling.

## Troubleshooting

- **`Existing file '…' would be clobbered`** on a switch: a real file sits
  where home-manager wants to put a link. Move it away (or merge it into
  `configs/`) and run `nrs` again. The first `./bootstrap` does this for you
  with `*.before-nix` backups.
- **`systemd isn't running`** (wsl): see step 2 of [wsl](#wsl).
- **`Nix is installed but has no nix-daemon service`**: an older Nix install
  (for example one made while WSL had systemd off) is in the way. Remove it,
  open a new terminal, and re-run `./bootstrap`, which installs Nix again with
  the service:
  ```bash
  # put back the shell files the old installer edited
  for f in /etc/bashrc /etc/bash.bashrc /etc/zshrc /etc/zsh/zshrc; do
    [ -e "$f.backup-before-nix" ] && sudo mv "$f.backup-before-nix" "$f"
  done
  sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf \
    ~root/.nix-profile ~root/.nix-defexpr ~root/.nix-channels ~root/.cache/nix
  rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.local/state/nix ~/.cache/nix
  # the build users, if `getent group nixbld` lists any
  for i in $(seq 1 32); do sudo userdel "nixbld$i"; done
  sudo groupdel nixbld
  ```
- **`This non-NixOS system is not yet set up to use the GPU`** or **`GPU
  drivers require an update`** (printed by a switch): re-run `./bootstrap`,
  which runs the GPU setup. The warning also prints the exact `sudo` command.
- **Black screen and a frozen machine when COSMIC or Hyprland starts**
  (wing-zero): Panel Self Refresh is still on. `cat /proc/cmdline` should
  include `i915.enable_psr=0`; if it doesn't, re-run `./bootstrap` and
  reboot. To get in meanwhile, press `e` at the boot menu, add
  ` i915.enable_psr=0` to the end of the kernel options, and boot.
- **Red screen at boot on wing-zero**: the Surface Pro 3 shows it whenever
  Secure Boot is off or the factory keys were replaced. To boot with Secure
  Boot on and the factory keys kept, follow
  [wing-zero Secure Boot](docs/wing-zero-secure-boot.md). It's done by hand,
  once; bootstrap doesn't touch the bootloader.
- **New terminals still start bash after bootstrap** (none of the config
  applies): the login shell changed, but this session started before that.
  Reboot, or log out and back in. `getent passwd roy | cut -d: -f7` shows the
  login shell; `exec zsh` switches the current terminal right away.
- **`Unknown host`**: the hostname doesn't match a host. Fix the hostname or
  pass `--host <name>`.
- **`These files are not tracked by git`**: `git add nix/`, then re-run.
- Tool-specific problems (nvim plugins, language servers…) are on that tool's
  page under `docs/`.
