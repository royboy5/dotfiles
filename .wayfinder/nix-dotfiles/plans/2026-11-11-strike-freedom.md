# Nix Port, Plan 2: `strike-freedom` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `strike-freedom` (Surface Pro 3, fresh EndeavourOS) as the first GUI host. `./bootstrap` installs its pacman list (including COSMIC, Hyprland, Ghostty and the Nerd Fonts), turns on its services, applies `roy@strike-freedom` and runs the GPU setup. The Ghostty and Hyprland configs are live-linked on GUI hosts only.

**Architecture:** Plan 1's shape is unchanged. `nix/flake.nix` gains `homeConfigurations."roy@strike-freedom" = mkHome "strike-freedom"`. `nix/hosts/strike-freedom.nix` imports the generic-linux target and a new `nix/home/gui.nix`, which owns the GUI-only links. Bash gains `lib/hosts/strike-freedom.sh` (`host_strike_freedom`) plus small shared helpers in `lib/common.sh`.

**Tech Stack:** Nix flakes, home-manager (master on `nixpkgs-unstable`), bash, bats, pacman/systemd on EndeavourOS.

**Spec:** `.wayfinder/nix-dotfiles/map.md` and its tickets. This plan uses tickets 04 (package ownership), 05 (bootstrap flow: the Arch row, as amended), 06 (ghostty), 09 (`strike-freedom`, including the 2026-11-11 amendment), 12 (fonts), 13 (Hyprland, amended for the Lua config) and 14 (cutover). Plan 1 (`plans/2026-11-10-shared-base-and-wsl.md`) built everything this plan extends.

**Later plans:** `unicorn-rx0` (`nixos/`, merge to `master`), then `qant-00` (Bazzite).

## Global Constraints

- Work on branch `nix` in the existing worktree. Push with `git push -q git@github.com:royboy5/dotfiles.git nix`.
- **The README and docs change in the same commit as the code they describe.** The user follows the README on the machine.
- **Before adopting any config file, show the user the diff against its sources and wait for approval** (map Notes). These are the "User gate" steps.
- **The dotfiles don't set up EndeavourOS itself.** Installer desktop choice, display manager, greeter and session defaults are out of scope (ticket 09 amendment). Bootstrap only installs COSMIC and Hyprland and links configs. COSMIC has no config in the repo.
- **Packages come from pacman `[extra]` only, with no AUR.** Arch list (bash array `PACMAN_PACKAGES_STRIKE_FREEDOM`):
  - from plan 1's shared list: `zsh ghostty docker reflector wl-clipboard`
  - added here: `cosmic hyprland thermald ttf-firacode-nerd ttf-jetbrains-mono-nerd`

  `cosmic` is the Arch package group. All of these were checked on archlinux.org on 2026-11-11: hyprland 0.57.2, ghostty 1.4.0, and the `cosmic` group includes `cosmic-session`, `cosmic-greeter` and `xdg-desktop-portal-cosmic`.
- **Ensure only, no general upgrade:** `sudo pacman -Syu --needed --noconfirm <list>`. `--noconfirm` selects every member of the `cosmic` group.
- **Services:** `docker.service`, `reflector.timer` and `thermald.service` are enabled with `--now`. `roy` is added to the `docker` group.
- **Fixed paths:**
  - `/usr/bin/zsh` stays the login shell.
  - The GPU setup runs as `sudo <absolute store path>/non-nixos-gpu-setup` after every switch. `sudo` doesn't see the user's PATH.
- **Fonts and GUI configs:** home-manager installs no fonts, and `wsl` gets neither the ghostty nor the hypr link.
- **Authoring happens on the Mac** (`aarch64-darwin`): `nix eval`, bats and shellcheck run there, and Ghostty 1.4.0 is installed there for `+validate-config`. Building and activating happen only on `strike-freedom`.
- **Hyprland 0.57 replaced `hyprland.conf` with a Lua config:** the upstream example is `example/hyprland.lua`, and the terminal is set by `local terminal = "kitty"`. Ticket 13 is amended to match. Its intent is unchanged: copy the stock example once, change only the terminal to ghostty, and link it.

## Review Focus

1. **Re-running after the docker group was added, but before re-login.** `id -nG` in the same session doesn't list `docker` yet. Expect: `usermod -aG` is skipped based on the group database (`getent group docker`), not the current session. Covered in Task 3.
2. **First run under `--dry` on a fresh install**, with no Nix and no `non-nixos-gpu-setup` on PATH. Expect: the GPU step warns and skips. It must not fail or print a bogus path. Covered in Task 3.
3. **The hostname left at the installer's default** (e.g. `endeavour`). Expect: the unknown-host error lists `strike-freedom`. The README install section says to set the hostname, or to pass `--host strike-freedom`. Covered in Task 3 (`resolve_host` test with the new `KNOWN_HOSTS`).
4. **GUI links leaking to `wsl`.** Expect: `roy@wsl` has no `ghostty` or `hypr` entry in `xdg.configFile`. Covered in Task 2 (eval checks run for both hosts).
5. **`pacman` hitting an interactive prompt** (a group selection, or a provider choice such as `ttf-font`). Expect: `--noconfirm` takes the defaults; the README lists the packages so a stalled run can be diagnosed. Verified in Task 4 acceptance.

---

### Task 1: Plan 1's deferred minors

Spec: plan 1 final review (deferred minors). The README's hyphen note is in Task 3, where the first hyphenated host lands.

**Files:**
- Modify:
  - `lib/common.sh` (`hm_switch`, `check_untracked`, `ensure_flakes`)
  - `nix/home/shell/zsh.nix:82` (comment)
- Test: `tests/bootstrap.bats`

**Interfaces:**
- Produces: no new names. Behaviour changes only:
  - `hm_switch` under `--dry` passes `--no-out-link`, so no `./result` link appears.
  - `check_untracked` refuses any untracked file under `nix/`.
  - `ensure_flakes` starts a new line if `nix.conf` lacks a trailing newline.

- [ ] **Step 1: Write failing tests:**
  - `hm_switch dry run doesn't leave a result link`: run with `BOOTSTRAP_DRY=1`, once with `home-manager` on PATH and once without (with `nix` stubbed). `$CALLS` contains `build --no-out-link` both times.
  - `check_untracked refuses untracked non-nix files under nix/`: an untracked `nix/home/scripts/new.sh` in a temp git repo. Expect status 1, and the output contains `new.sh`.
  - `ensure_flakes keeps an unterminated last line intact`: `NIX_CONF` holds `build-users-group = nixbld` with no trailing newline. Afterwards `tail -n 1` equals the flakes line, and `grep -c '^build-users-group = nixbld$'` is 1. The test's `sudo` stub must run its arguments (`"$@"`) so that `tee -a` really writes.
- [ ] **Step 2:** `nix shell nixpkgs#bats -c bats tests/` shows exactly these three failing.
- [ ] **Step 3: Implement.**
  - **`hm_switch`:** add `--no-out-link` to both build invocations (installed `home-manager build`, and `nix run home-manager/master -- build`).
  - **`check_untracked`:** pathspec `nix/`.
  - **`ensure_flakes`:** when the file is non-empty and its last byte isn't a newline (`[[ -s f && -n "$(tail -c1 f)" ]]`), prepend `\n` to the line it appends.
  - **`zsh.nix` comment:** replace "gitignored" with "not in the repo".
- [ ] **Step 4:** bats is all green and `shellcheck bootstrap lib/*.sh lib/hosts/*.sh` is clean. `tests/eval.sh` still prints 98/98.
- [ ] **Step 5:** Commit `fix(bootstrap): no result link on --dry, all untracked nix/ files, unterminated nix.conf`.

### Task 2: `roy@strike-freedom` with the GUI links (ghostty, Hyprland)

Spec: tickets 03, 06 (ghostty), 09, 13 (amended), 12 (font name only).

**Files:**
- Create:
  - `nix/hosts/strike-freedom.nix`
  - `nix/home/gui.nix`
  - `configs/ghostty/config`
  - `configs/hypr/hyprland.lua`
- Modify:
  - `nix/flake.nix`
  - `tests/eval.sh`
  - `README.md` (Layout, "Where does it go?")
  - `.wayfinder/nix-dotfiles/tickets/13-hyprland-config.md` (amendment)

**Interfaces:**
- Produces:
  - `homeConfigurations."roy@strike-freedom"`
  - `nix/home/gui.nix`, a module imported only by GUI host files. It sets `xdg.configFile."ghostty".source = linkConfig "ghostty"` and `xdg.configFile."hypr".source = linkConfig "hypr"`. `unicorn-rx0` imports it in plan 3.
  - `nix/hosts/strike-freedom.nix`: `imports = [ ../home/targets/generic-linux.nix ../home/gui.nix ]`. `targets.genericLinux.gpu.enable` is left at its default (`true`).
  - `tests/eval.sh <host>` runs the shared checks against any host. The suite command becomes `tests/eval.sh wsl && tests/eval.sh strike-freedom`.

- [ ] **Step 1: Write failing eval checks.** In `tests/eval.sh`:
  - Use `$HOST` in the `nrs` check: `…#roy@$HOST`.
  - Turn the `gpu.enable` check into a `case "$HOST"`: `wsl` expects `false`, `strike-freedom` expects `true`.
  - Add `has_link <name>` / `lacks_link <name>`, which test `builtins.hasAttr <name> config.xdg.configFile`.
    - For `wsl`: `lacks_link ghostty`, `lacks_link hypr`.
    - For `strike-freedom`: `has_link ghostty`, `has_link hypr`, and `lacks_pkg ghostty` and `lacks_pkg hyprland` (they come from pacman).
  - Add file checks, run for any host:
    - `configs/hypr/hyprland.lua` has the exact line `local terminal    = "ghostty"`, with the spacing as in upstream.
    - it has no `kitty`
    - `configs/ghostty/config` contains `theme = "TokyoNight Storm"` and no `macos-` or `super+` lines.
- [ ] **Step 2:** `tests/eval.sh strike-freedom` fails: the output doesn't exist yet. `tests/eval.sh wsl` fails only on the missing files.
- [ ] **Step 3: Write the configs.**
  - **`configs/hypr/hyprland.lua`:** the upstream example at the version Arch ships, from `https://raw.githubusercontent.com/hyprwm/Hyprland/v0.57.2/example/hyprland.lua`. Change only `local terminal    = "kitty"` to `"ghostty"`. The `dolphin` file manager and the launcher stay as they are (ticket 13).
  - **`configs/ghostty/config`:** `~/.dotfiles/configs/ghostty/config` with three changes from ticket 06:
    - `macos-titlebar-style` removed
    - `theme = "TokyoNight Storm"`
    - the four `super+h/j/k/l` binds removed

    Keep the commented Ctrl-Shift lines and their comment.
  - Validate: `ghostty +validate-config --config-file=configs/ghostty/config` prints nothing and exits 0.
- [ ] **Step 4: User gate.** Show the user `diff` of the example against `hyprland.lua` (one line), and `diff ~/.dotfiles/configs/ghostty/config configs/ghostty/config`. Wait for approval.
- [ ] **Step 5: Wire it up.**
  - Add `gui.nix`, the host file and the flake output. `gui.nix` gets a header comment: GUI-only links; the apps themselves come from the system layer.
  - `git add`, then both eval runs pass.
  - README:
    - **Layout:** add `gui.nix` under `home/` and `hosts/<host>.nix`. Add the bullets:
      - **ghostty:** `configs/ghostty/config`, GUI hosts only. Tokyo Night Storm, FiraCode Nerd Font Mono.
      - **Hyprland:** `configs/hypr/hyprland.lua`, GUI hosts only. Hyprland's stock example with ghostty as the terminal. The launcher and file-manager binds point at apps that aren't installed.
    - **"Where does it go?":** add a row, "A config only GUI hosts use | `configs/<app>/`, linked from `nix/home/gui.nix`".
  - Append to ticket 13: `*Amended 2026-11-11:* Hyprland 0.57 replaced hyprland.conf with Lua; the copied file is configs/hypr/hyprland.lua and the change is local terminal = "ghostty".`
- [ ] **Step 6:** Commit `feat(nix): roy@strike-freedom with ghostty and Hyprland links on GUI hosts`.

### Task 3: `./bootstrap` for `strike-freedom`

Spec: ticket 05 (Arch row, amended), 04 and 12 (list), 09 (thermald), 14.

**Files:**
- Create: `lib/hosts/strike-freedom.sh`
- Modify:
  - `bootstrap` (`KNOWN_HOSTS=(wsl strike-freedom)`)
  - `lib/common.sh`
  - `tests/bootstrap.bats`
  - `README.md`

**Interfaces:**
- Consumes: Task 2's `roy@strike-freedom`.
- Produces, in `lib/common.sh`:
  - `ensure_service <unit>…`: `execute sudo systemctl enable --now <unit>` for each unit not already `systemctl is-enabled --quiet`.
  - `ensure_group <group>`: when `getent group <group>` doesn't list `$USER`, runs `execute sudo usermod -aG <group> "$USER"` and warns `Log out and back in for the <group> group to apply.`
  - `ensure_gpu_setup`: resolves `command -v non-nixos-gpu-setup`. If it's missing, warns (the same wording pattern as `ensure_rustup`, mentioning `--dry`) and returns 0. Otherwise runs `execute sudo "$(readlink -f "$path")"`.
- Produces, in `lib/hosts/strike-freedom.sh`: `PACMAN_PACKAGES_STRIKE_FREEDOM`, and `host_strike_freedom`, which runs in this order:
  1. `execute sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES_STRIKE_FREEDOM[@]}"`
  2. `ensure_service docker.service reflector.timer thermald.service`
  3. `ensure_group docker`
  4. `ensure_login_shell /usr/bin/zsh`
  5. `ensure_nix`
  6. `ensure_flakes`
  7. `lock_flake`
  8. `hm_switch strike-freedom`
  9. `ensure_gpu_setup`
  10. `ensure_tpm`
  11. `ensure_rustup`

- [ ] **Step 1: Write failing tests.** Add `pacman`, `getent` and `readlink` handling to `setup` as needed. Stubs record calls; a custom stub can make `systemctl is-enabled` fail for a chosen unit.
  - **`host_strike_freedom`:**
    - `installs the pacman list, then switches roy@strike-freedom`: `$CALLS` has `pacman -Syu --needed --noconfirm` with `cosmic`, `hyprland`, `ghostty` and `ttf-firacode-nerd`. The `pacman` line comes before the `nix … run home-manager/master` line, which contains `roy@strike-freedom`.
    - `runs the GPU setup after the switch`.
  - **`ensure_service`:**
    - `enables only units that aren't enabled`: `reflector.timer` is enabled and `docker.service` isn't. Expect exactly one `enable --now docker.service`.
  - **`ensure_group`:**
    - `adds roy when the group database lacks him`: `getent` prints `docker:x:970:`. Expect `usermod -aG docker roy` and the output contains `Log out`.
    - `skips when getent lists roy` (Review Focus 1): `getent` prints `docker:x:970:alice,roy`. Expect no `usermod`.
  - **`ensure_gpu_setup`:**
    - `runs the absolute store path with sudo`: a stub `non-nixos-gpu-setup` on PATH. Expect `sudo` to be called with the resolved absolute path.
    - `warns and skips when it isn't installed` (Review Focus 2): status 0, no `sudo` call, and the output mentions `--dry`.
  - **`resolve_host`:**
    - `resolve_host lists strike-freedom for an unknown hostname` (Review Focus 3).
- [ ] **Step 2:** The new tests fail; the rest pass.
- [ ] **Step 3: Implement** the helpers, the host file and `KNOWN_HOSTS`. Header comment on the host file: `strike-freedom: Surface Pro 3, EndeavourOS (the Arch path). GUI host: COSMIC and Hyprland side by side; the session is picked at login, which this repo doesn't configure.`
- [ ] **Step 4:** bats and shellcheck are clean. `./bootstrap --dry --host strike-freedom` on the Mac is not a test (`check_repo_path` refuses there); skip it.
- [ ] **Step 5: README, same commit.**
  - **Status table:** `wsl` → `migrated`, `strike-freedom` → `being migrated`.
  - **Table of contents:** add `strike-freedom` under Install, after `wsl`.
  - **New section `### strike-freedom`** (Surface Pro 3, EndeavourOS):
    1. **Before wiping:** follow [Reinstalling a host](#reinstalling-a-host).
    2. **Install EndeavourOS.** Any desktop option is fine. Set the hostname to `strike-freedom` in the installer (or pass `--host strike-freedom` later), and create the user `roy`.
    3. **Restore `~/.ssh`**, then clone (`-b nix`) and run `./bootstrap --dry`, then `./bootstrap`. Say what it does:
       - the pacman list, written out
       - the services and the docker group
       - zsh as the login shell
       - Nix, home-manager, the GPU setup, TPM and rustup
    4. **Log out and back in** (docker group, login shell, session variables). Pick COSMIC or Hyprland at the login screen. In Hyprland, SUPER+Q opens Ghostty.
    5. **Restore secrets** into `~/.config/zsh/local_env.zsh` and zsh history into `~/.local/state/zsh/`.
    6. **Open Ghostty** (zellij starts), then press `prefix + I` in tmux once.
  - **"Adding a new host" step 3:** a hyphen in the host name becomes an underscore in the function: `host_strike_freedom`.
  - **Layout:** add `gui.nix` if Task 2 hasn't already.
  - **Troubleshooting:** add `This non-NixOS system is not yet set up to use the GPU` / `GPU drivers require an update`: re-run `./bootstrap`, which runs the setup. The command it runs is printed in that warning.
- [ ] **Step 6:** Commit `feat(bootstrap): strike-freedom host (pacman list, services, GPU setup)`, then push.

### Task 4: Migrate `strike-freedom` (acceptance)

Spec: ticket 14 (order, backups, fix forward); ticket 09 open checks; plan 1's proto ruling.

The user does the install. Work through the README section with them, and fix forward on `nix` (TDD for any bootstrap bug; docs in the same commit). Each check below is confirmed individually by the user, not as a group:

- [ ] Backups taken per "Reinstalling a host".
- [ ] `./bootstrap --dry` lists the pacman command and prints no errors.
- [ ] `./bootstrap` finishes with `Done.`.
- [ ] A second run changes nothing:
  - no `enable --now` and no `usermod`
  - home-manager reports no changes
  - the GPU setup is idempotent
- [ ] After logging back in:
  - `echo $SHELL` is `/usr/bin/zsh`
  - `id -nG` lists `docker`
  - `docker run --rm hello-world` works
- [ ] The COSMIC session starts.
- [ ] The Hyprland session starts:
  - with no "autogenerated config" banner
  - SUPER+Q opens Ghostty, in Tokyo Night Storm and FiraCode
- [ ] `readlink ~/.config/hypr ~/.config/ghostty` point into `~/.dotfiles/configs/`.
- [ ] **Navigation in Ghostty:**
  - Ctrl-hjkl crosses nvim splits and zellij panes (ticket 10's Ghostty test)
  - Ctrl-Shift-h/l switches zellij tabs
- [ ] `nrs` works.
- [ ] **Power** (ticket 09, open check): record which of these are active.
  - `systemctl is-active power-profiles-daemon system76-power tlp`
  - Expected: one power daemon, and tlp inactive.

  If two conflict, that's a finding to rule on.
- [ ] `thermald` is active.
- [ ] **proto** (plan 1 ruling, carried over): in a repo with a `.prototools` pin, `node --version` is the pinned version. Outside it, `which node` is the Nix one.
- [ ] Commit `chore(strike-freedom): acceptance` with the README status `migrated`.

### Final review

Run the final whole-branch review over `<commit that added this plan>..HEAD`, per the executor skill. Then finish with finishing-a-development-branch, option 3 (keep `nix`). The branch merges after `unicorn-rx0` (ticket 14).
