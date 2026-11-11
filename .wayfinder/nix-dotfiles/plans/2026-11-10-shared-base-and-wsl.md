# Nix Port, Plan 1: Shared Base + `wsl` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace this repo's bash setup with a Nix flake whose shared home-manager user layer runs on the first migrated host, `wsl` (Fedora under WSL), installed by a new re-runnable `./bootstrap`, and documented in a rewritten README and `docs/`.

**Architecture:** `nix/flake.nix` exposes `homeConfigurations."roy@wsl"`. It is built from the shared `nix/home/` modules (one topic per file, each owning its packages, links, aliases and env vars), the `nix/home/targets/generic-linux.nix` target, and `nix/hosts/wsl.nix`. Config files stay in `configs/` and are live-linked with `linkConfig` (`mkOutOfStoreSymlink`); zsh is the one declared exception. The bash `./bootstrap` dispatches on hostname and runs `lib/hosts/<host>.sh` on top of the shared steps in `lib/common.sh`.

**Tech Stack:** Nix flakes, home-manager (master, following `nixpkgs-unstable`), bash, bats, the NixOS community nix-installer.

**Spec:** `.wayfinder/nix-dotfiles/map.md` and the resolutions in `.wayfinder/nix-dotfiles/tickets/*.md`. Read the ticket a task cites before starting it. The reference repo is `~/.dotfiles` (work repo, macOS; read-only: never edit it).

**Later plans (not this one):** `strike-freedom` (pacman list, GPU setup, ghostty/Hyprland links, fonts), `unicorn-rx0` (`nixos/`, merge to `master`), `qant-00` (Bazzite). Each is written after the previous host passes.

## Global Constraints

- Work on branch `nix`, cut from `master`. Never commit to `master` in this plan.
- Every host: username `roy`, `x86_64-linux`, `nixpkgs-unstable`. `home.stateVersion = "26.05"`.
- The repo lives at `~/.dotfiles` on every host. `linkConfig` and aliases derive that path from one definition, never a hardcoded string per file.
- **Before adopting any config file, show the user the diff against both sources (this repo's `master` and `~/.dotfiles`) and wait for approval** (map Notes). Tasks mark these as "User gate" steps. They cannot be done by a subagent.
- Work-only content never enters the repo: `gke-creds`, `cloud.nix`, fp-ev clusters, `envs/ma.nix`, `GCP_*` registry vars, the tmux k8s segment, glab.
- Dropped everywhere: VS Code, Cursor, `claude-code`, `1password-cli`, `antigravity-cli`, `terraform`, opencode, Flutter, Android SDK, Volta, Mason, Comment.nvim, jupyterlab, global `python3`.
- Flakes see only git-tracked files: `git add` new `nix/` files before any `nix eval`.
- Authoring happens on the Mac (`aarch64-darwin`, no Linux builder). `nix eval` checks run there; anything that builds or activates runs on the `wsl` host. On the Mac, `~/.dotfiles` is the **work** repo: run `./bootstrap` only on `wsl`.
- Eval shorthand used below: `E=".#homeConfigurations.\"roy@wsl\".config"`, run from `nix/`.

## Review Focus

1. **Re-running after a partial run** (Nix installed but not on PATH in the current shell; first switch failed halfway). Expect: bootstrap sources the daemon profile and continues. Covered in Task 7 (`load_nix_env` test, first-switch detection test).
2. **The WSL hostname is the Windows computer name, not `wsl`.** Expect: unknown-host error listing known hosts and suggesting `--host wsl`. Covered in Task 7 (`resolve_host` tests); the README `wsl` section says to set `[network] hostname = wsl`.
3. **Running as root or as a user other than `roy`** (e.g. `sudo ./bootstrap`). Expect: refuse before changing anything. Covered in Task 7.
4. **Leftover `ln -sf` links from the old clone, and pre-existing dotfiles.** Expect: old links removed before the first switch (Task 8 step), and real files moved to `*.before-nix` and listed at the end of the run (Task 7 `list_backups` test).
5. **Zellij auto-start in non-interactive or nested shells** (`ssh host cmd`, `scp`, a shell inside zellij). Expect: no auto-start. Covered in Task 2 (initContent guard assertions).

---

### Task 1: `nix` branch, old setup removed, flake skeleton for `roy@wsl`

Spec: tickets 03, 05 (repo path), 14 (branch).

**Files:**
- Delete: `os/`, `bootstrap`, `lib/helpers.sh`, `configs/zsh/` (move `local_envs.zsh.sample` first, see Task 2)
- Create: `nix/flake.nix`, `nix/home/default.nix`, `nix/home/targets/generic-linux.nix`, `nix/hosts/wsl.nix`, `nix/flake.lock`

**Interfaces:**
- Produces:
  - `extraSpecialArgs = { username = "roy"; hostName = "<host>"; }` for every home config.
  - Module arg `dotfiles` (string, `"${config.home.homeDirectory}/.dotfiles"`), defined once in `home/default.nix`.
  - Module arg `linkConfig : string -> path` (`mkOutOfStoreSymlink "${dotfiles}/configs/${path}"`), as in `~/.dotfiles/nix/home/default.nix`.
  - `mkHome = hostName: home-manager.lib.homeManagerConfiguration { pkgs = nixpkgs.legacyPackages.x86_64-linux; extraSpecialArgs = …; modules = [ ./home ./hosts/${hostName}.nix ]; }` in `flake.nix`.
  - Host file shape: `{ imports = [ ../home/targets/generic-linux.nix ]; … host overrides }`.
  - `home/default.nix` imports topic modules; later tasks append to its `imports`.

- [ ] **Step 1:** `git switch -c nix master`, then `git rm -r os bootstrap lib/helpers.sh` (keep `configs/zsh/` until Task 2). Commit `chore: remove bash setup for the Nix port`.
- [ ] **Step 2: Write the flake.** Inputs: `nixpkgs` (`nixpkgs-unstable`), `home-manager` (follows nixpkgs). Output `homeConfigurations."roy@wsl" = mkHome "wsl"`. `home/default.nix` sets `home.username`, `home.homeDirectory = "/home/${username}"`, `home.sessionPath = [ "$HOME/.local/bin" ]`, `programs.home-manager.enable`, `stateVersion`. `generic-linux.nix` sets `targets.genericLinux.enable = true`. `hosts/wsl.nix` sets `targets.genericLinux.gpu.enable = false`.
- [ ] **Step 3: Verify the evaluation.** `git add nix && cd nix && nix flake lock`, then:
  - `nix eval --raw $E.home.homeDirectory` → `/home/roy`
  - `nix eval $E.targets.genericLinux.enable` → `true`
  - `nix eval $E.targets.genericLinux.gpu.enable` → `false`
- [ ] **Step 4:** Commit `feat(nix): flake skeleton with roy@wsl`.

### Task 2: Shell module (zsh, starship, everyday aliases)

Spec: tickets 07, 05 (everyday commands), 06 (starship), 10 (no Ctrl-l rebind).

**Files:**
- Create: `nix/home/shell/default.nix`, `nix/home/shell/zsh.nix`, `nix/home/shell/starship.nix`, `configs/starship/starship.toml`, `configs/zsh/local_env.zsh.sample`
- Delete: the rest of `configs/zsh/`
- Modify: `.gitignore` (drop the Packer and `configs/zsh/local*` lines; no secret is ever in the repo now)

**Interfaces:**
- Consumes: `dotfiles`, `linkConfig`, `username`, `hostName`.
- Produces: aliases `nrs` and `ngc`, defined per target in `targets/generic-linux.nix` so the NixOS plan can define its own: `nrs = home-manager switch --flake ${dotfiles}/nix#${username}@${hostName}`, `ngc = nix-collect-garbage -d && sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage -d` (user profiles, then root's; absolute path because `sudo` doesn't see the user's PATH). Also `nfu = nix flake update --flake ${dotfiles}/nix`, `nus = nix flake update --flake ${dotfiles}/nix/shells`, `dot = cd ${dotfiles}` in `zsh.nix`. Other modules add to `programs.zsh.initContent` at the default order (between 550 and the local-env/autostart block at `lib.mkOrder 1500`).

- [ ] **Step 1: Write failing eval checks.** These fail until the module exists:
  - `nix eval --raw $E.home.shellAliases.nfu` → `nix flake update --flake /home/roy/.dotfiles/nix`
  - `nix eval --raw $E.home.shellAliases.nrs` → `home-manager switch --flake /home/roy/.dotfiles/nix#roy@wsl`
  - `nix eval --raw $E.home.shellAliases.ngc` → `nix-collect-garbage -d && sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage -d`
  - `nix eval $E.programs.zsh.history.size` → `10000`
  - `nix eval --raw $E.programs.zsh.history.path` → `/home/roy/.local/state/zsh/history`
  - `nix eval --raw $E.programs.zsh.initContent | grep -c 'ZELLIJ_AUTOSTART'` → ≥1
  - the autostart block is guarded by `[[ -o interactive ]]`, `-z $ZELLIJ`, `-z $SSH_CONNECTION` and `command -v zellij`, and sits after the `local_env.zsh` source line. Check with `grep -n` order.
- [ ] **Step 2: Implement `zsh.nix`.** Port `~/.dotfiles/nix/home/shell/zsh.nix` without Homebrew, Docker Desktop, `ndr` or `ulimit` (`ngc` moves to the target file, above). Apply ticket 07: `dotDir`, `enableCompletion = false`, zsh-autocomplete at `lib.mkOrder 550`, history settings and the full `setopt` list, `AUTO_CD`, `mkcd`/`extract`, `local_env.zsh` then autostart at `lib.mkOrder 1500`. Aliases: safety, navigation, `-`, `dl`/`dt`/`src`, `reload = exec zsh`, plus `nfu`, `nus` and `dot` above. No `~` alias.
- [ ] **Step 3: User gate.** Show the user the full alias set (this module plus what Tasks 3–6 add, from ticket 07's list) and `starship.toml` (`~/.dotfiles` version minus the kubernetes module and its GKE pattern; `DEV_SHELL` segment kept). Adopt after approval.
- [ ] **Step 4:** Move the sample to `configs/zsh/local_env.zsh.sample`. It lists exports only plus a commented `# export ZELLIJ_AUTOSTART=0`. Remove the rest of `configs/zsh/`.
- [ ] **Step 5:** Run the Step 1 checks. All pass. Commit `feat(nix): zsh and starship`.

### Task 3: CLI tools and git

Spec: tickets 04 (package list), 06 (git), 07 (aliases).

**Files:**
- Create: `nix/home/cli.nix`, `nix/home/git.nix`, `configs/git/ignore`
- Modify: `configs/git/config`

- [ ] **Step 1: Failing check.** `nix eval --json $E.home.packages --apply 'map (p: p.pname or p.name)'` includes every name in: `bat eza fd fzf ripgrep jq yq-go httpie jless k9s tree curl wget htop git git-lfs delta lazygit`. It must not include `glab`.
- [ ] **Step 2: Implement.** Port `~/.dotfiles` `cli.nix` and `git.nix` (no glab). Add `jless`, `k9s` and the `catp = bat` alias. Keep `git_current_branch` in `git.nix` `initContent`. Link: `xdg.configFile."git".source = linkConfig "git"`.
- [ ] **Step 3: User gate.** Propose `configs/git/config` from `~/.dotfiles/configs/git/config` with email `me@royeng.com`, delta pager, `excludesfile = ~/.config/git/ignore`. `configs/git/ignore` has exactly two lines, `.direnv/` and `.envrc`. Show the diff against this repo's current config and adopt after approval.
- [ ] **Step 4:** Run the Step 1 check. It passes. `nix eval --raw $E.home.shellAliases.lg` → `lazygit`. Commit `feat(nix): cli tools and git`.

### Task 4: tmux and zellij, including Ctrl-hjkl navigation (zellij side)

Spec: tickets 06 (tmux, zellij), 10 (navigator).

**Files:**
- Create: `nix/home/terminal.nix`
- Move: `configs/tmux/.tmux.conf` → `configs/tmux/tmux.conf`
- Replace: `configs/zellij/config.kdl`, `configs/zellij/layouts/dev.kdl` (from `~/.dotfiles`)

**Interfaces:** Produces `~/.tmux.conf` and `~/.config/zellij` links. TPM is cloned by bootstrap (Task 7), not Nix.

- [ ] **Step 1: Failing check.** Packages include `tmux` and `zellij`. `nix eval --json $E.xdg.configFile --apply builtins.attrNames` includes `"zellij"`. It does not include `"ghostty"`, because ghostty is GUI-host-only and comes in a later plan.
- [ ] **Step 2: Implement `terminal.nix`.** Packages and the two links, no ghostty.
- [ ] **Step 3: Zellij edits from ticket 06.**
  - Drop `copy_command`, the normal-mode Ctrl-hjkl focus binds and the Ctrl-m Move bind.
  - Keep Ctrl-Shift-h/l tabs, the Ctrl-q unbind with quit on Ctrl-o q, and `Alt d`/Ctrl-t d.
  - Strip the `cwd "/Users/reng/projects/vioc"` lines from `dev.kdl`.
  - Add the ticket 10 binds: in `shared_except "locked"`, `Ctrl h/j/k/l` → `MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm"` with `name "move_focus"`, `move_mod "ctrl"` and payloads `left`/`down`/`up`/`right`.
- [ ] **Step 4: User gate.** Show the tmux file, confirming no k8s segment and that the TPM path matches `~/.tmux/plugins/tpm`. Show the zellij diff. Adopt after approval.
- [ ] **Step 5:** Run the Step 1 check. It passes. `grep -c vim-zellij-navigator configs/zellij/config.kdl` → `4`. Commit `feat(nix): tmux and zellij`.

### Task 5: Neovim (Nix replaces Mason; smart-splits)

Spec: tickets 06 (nvim), 08 (language servers), 10 (smart-splits).

**Files:**
- Create: `nix/home/nvim.nix`, `configs/nvim/lua/plugins/smart-splits.lua`, `configs/nvim/lua/plugins/fidget.lua`
- Modify: `configs/nvim/lua/plugins/lsp.lua`, `treesitter.lua`, `bufferline.lua`, `configs/nvim/lua/config/keymaps.lua`

- [ ] **Step 1: Failing check.** Packages include `neovim`, `tree-sitter`, `lua-language-server`, `typescript-language-server`, `vscode-langservers-extracted`, `stylua`, `prettier`, `black` and `isort`. `nix eval --raw $E.home.sessionVariables.EDITOR` → `nvim`. `grep -ri mason configs/nvim` → no output.
- [ ] **Step 2: `nvim.nix`.** Port from `~/.dotfiles` without clangd and cssmodules. Add stylua, prettier, black and isort. Keep the `vi`/`vim`/`v` aliases. gopls and zls come from Task 6; rust-analyzer comes from rustup.
- [ ] **Step 3: Config edits.**
  - Remove the Mason plugins from `lsp.lua`.
  - Replace `treesitter.lua` with the `~/.dotfiles` `main`-branch version, adding `python`, `go`, `html`, `markdown` and `markdown_inline` to its parser list.
  - Move the Shift-h/l maps into `bufferline.lua`.
  - Add fidget.
  - Add `smart-splits.lua` (`^3.0.0`, dependency `smart-splits-nvim/backend-zellij-lua` v1, `mux.backend = 'smart-splits-backend-zellij-lua'`, `<C-h/j/k/l>` → `move_cursor_left/down/up/right`) and delete the four normal-mode `<C-w>h/j/k/l` maps from `keymaps.lua`. Terminal-mode maps stay.
- [ ] **Step 4: User gate.** Show the diff, and ask how `kulala_ls` should be provided: kulala.nvim's self-fetch, or dropping it (ticket 08). Apply the answer.
- [ ] **Step 5:** Run the Step 1 checks. They pass. Commit `feat(nix): neovim with Nix-provided language servers`.

### Task 6: Toolchains, direnv, dev shells, proto

Spec: tickets 08, 11.

**Files:**
- Create: `nix/home/dev/{default,golang,rust,nodejs,python,zig,proto}.nix`, `nix/home/scripts/project.sh`, `nix/shells/flake.nix`, `nix/shells/flake.lock`, `nix/shells/envs/.gitkeep`, `configs/proto/.prototools`

**Interfaces:** Produces the `project` command and the devShells `node`, `node22`, `node24`, `python312`, `python313`, `go` and `rust` under `nix/shells#devShells.x86_64-linux`, each exporting `DEV_SHELL`.

- [ ] **Step 1: Failing checks.**
  - Packages include `go`, `gopls`, `rustup`, `zig`, `zls`, `uv`, `ruff`, `nodejs`, `pnpm`, `proto` and `project`. They do not include `jupyterlab` or `python3`.
  - `nix eval --raw $E.home.sessionVariables.GOPATH` → `$HOME/src/go`
  - `nix eval --json $E.home.sessionPath` contains `$HOME/src/go/bin` and `$HOME/.cargo/bin`
  - `$E.programs.direnv.nix-direnv.enable` → `true`
  - `initContent` contains `proto activate zsh`
  - From `nix/shells`, `nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames` → `["go","node","node22","node24","python312","python313","rust"]`
  - `grep -r GCP_ nix/` → no output
- [ ] **Step 2: Implement.** Port `~/.dotfiles` `dev/`, `scripts/project.sh` and `shells/flake.nix`, with these changes:
  - `system = "x86_64-linux"`
  - no `GCP_*` vars and no jupyterlab
  - new `zig.nix` with `zig` and `zls`
  - `proto.nix` installs `proto`, adds `eval "$(proto activate zsh)"` to `initContent`, and links `home.file.".proto/.prototools".source = linkConfig "proto/.prototools"`
  - no `moon`, and no `MOON_TOOLCHAIN_FORCE_GLOBALS`
  - `envs/` starts empty
- [ ] **Step 3: User gate.** Propose `configs/proto/.prototools` with `[settings] auto-install = true` and nothing pinned. Adopt after approval.
- [ ] **Step 4:** Run the Step 1 checks. They pass. Commit `feat(nix): toolchains, dev shells and proto`.

### Task 7: `./bootstrap` (shared steps and the `wsl` path)

Spec: ticket 05 (all of it except the other hosts' rows), 06 (TPM), 08 (rustup).

**Files:**
- Create: `bootstrap`, `lib/utils.sh`, `lib/common.sh`, `lib/hosts/wsl.sh`, `tests/bootstrap.bats`

**Interfaces:**
- `bootstrap` is sourceable: `main "$@"` runs only when `${BASH_SOURCE[0]} == $0`. `KNOWN_HOSTS=(wsl)`; later plans append to it.
- `lib/utils.sh`: `log_info`, `log_success`, `log_warn`, `log_error`, and `execute cmd…`, which prints `[DRY] Would run: …` when `DRY_RUN=1`. Ported from `~/.dotfiles/libs/utils.sh` without the brew/xcode/link helpers.
- `lib/common.sh`:
  - `parse_args "$@"` sets `DRY_RUN`, `HOST_OVERRIDE` and `CLEAN_BACKUPS`. An unknown flag exits 2.
  - `resolve_host` echoes the host, or exits 1 with `Unknown host '<h>'. Known hosts: wsl. Use --host <name>.`
  - `check_user`: refuses when `EUID` is 0 or `USER` isn't `roy`.
  - `check_repo_path`: requires `DOTFILES_ROOT == $HOME/.dotfiles`.
  - `check_untracked`: refuses untracked `nix/*.nix` files.
  - `load_nix_env`: sources `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` if present.
  - `ensure_nix`: runs the community installer when `nix` is absent. It takes `"${INSTALL_ARGS[@]}"` so `qant-00` can pass `ostree --persistence=/var/lib/nix`.
  - `ensure_flakes`: the `/etc/nix/nix.conf` line, plus `systemctl restart nix-daemon` when it changed.
  - `lock_flake`: `nix flake lock` as the user.
  - `hm_switch <host>`: when `home-manager` isn't on PATH, runs `nix run home-manager/master -- switch -b before-nix --flake …#roy@<host>`; otherwise runs `home-manager switch --flake …`.
  - `ensure_tpm`: clones `https://github.com/tmux-plugins/tpm` into `~/.tmux/plugins/tpm` if absent.
  - `ensure_rustup`: runs `rustup default stable` and `rustup component add rust-analyzer` when no default toolchain is set.
  - `ensure_login_shell <path>`: runs `sudo usermod -s <path> roy` when `getent passwd roy` differs.
  - `list_backups`: prints `*.before-nix` files under `~` (maxdepth 1), `~/.config` (maxdepth 2) and `/etc` (maxdepth 2).
  - `clean_backups`: deletes them only after a `y` answer to a y/N prompt.
- `lib/hosts/wsl.sh`: `host_wsl` does the following in order.
  1. Require `/run/systemd/system`. If it's missing, print the `[boot] systemd=true` (`/etc/wsl.conf`) and `wsl --shutdown` instruction and exit 1.
  2. `execute sudo dnf install -y "${DNF_PACKAGES[@]}"`, where `DNF_PACKAGES=(zsh)` plus the installer prerequisites found in Task 8.
  3. `ensure_login_shell /usr/bin/zsh`
  4. `ensure_nix`
  5. `ensure_flakes`
  6. `lock_flake`
  7. `hm_switch wsl`
  8. `ensure_tpm`
  9. `ensure_rustup`

  No GPU setup.

- [ ] **Step 1: Write failing bats tests** in `tests/bootstrap.bats`. Each test sources `bootstrap` with stubbed commands on PATH (`hostname`, `nix`, `home-manager`, `sudo` and `git` as recording stubs in a temp dir):
  - `resolve_host` with `hostname -s` = `DESKTOP-AB12` exits 1 and its output contains `Known hosts: wsl` and `--host`
  - `--host wsl` resolves to `wsl` whatever the hostname is
  - `check_user` fails with `EUID=0`, and fails with `USER=reng`
  - `check_repo_path` fails when `DOTFILES_ROOT=/tmp/x`
  - `check_untracked` fails when an untracked `nix/foo.nix` exists in a temp git repo
  - `DRY_RUN=1 execute touch f` leaves no `f` and prints `[DRY] Would run: touch f`
  - `hm_switch wsl` without `home-manager` on PATH records `-b before-nix`; with it on PATH it does not
  - `list_backups` finds `~/.zshrc.before-nix` in a temp `HOME`
  - `clean_backups` answered `n` keeps the file; answered `y` deletes it
  - `parse_args --bogus` exits 2
  - `host_wsl` without `/run/systemd/system` (path injectable as `SYSTEMD_DIR`) exits 1 with `systemd=true` in its output
- [ ] **Step 2:** `nix shell nixpkgs#bats -c bats tests/` fails, because nothing is defined yet.
- [ ] **Step 3: Implement.** `main` runs: `parse_args`, then (if `CLEAN_BACKUPS`) `clean_backups` and exit, otherwise `check_user`, `check_repo_path`, `check_untracked`, `load_nix_env`, `resolve_host`, `host_$host`, `list_backups`. Under `--dry`, the Nix step builds without activating (`home-manager build`, or `nix run home-manager/master -- build` on the first run).
- [ ] **Step 4:** The bats suite passes. `nix shell nixpkgs#shellcheck -c shellcheck bootstrap lib/*.sh lib/hosts/*.sh` is clean.
- [ ] **Step 5:** Commit `feat: re-runnable bootstrap with the wsl path`.

### Task 8: Migrate `wsl` in place (acceptance)

Spec: ticket 14 (in-place host), ticket 10 (acceptance check), ticket 08 (proto check). **HITL: the user runs this on the WSL machine; the agent guides and records results.**

**Files:** Modify `lib/hosts/wsl.sh` (`DNF_PACKAGES`) and anything that a failure below forces, fixing forward on `nix`.

- [ ] **Step 1: Prepare.** Push `nix`. On `wsl`:
  - Remove the old clone's links: `find ~ -maxdepth 3 -type l -lname '*/.dotfiles/*' -print -delete`, after showing the list first.
  - Remove the old clone, then `git clone -b nix <remote> ~/.dotfiles`.
  - Set `[network] hostname = wsl` and `[boot] systemd=true` in `/etc/wsl.conf`, then run `wsl --shutdown` from Windows.
- [ ] **Step 2: Installer prerequisites.** Run `for c in curl tar xz git; do command -v $c || echo MISSING $c; done`. Add the packages providing anything missing to `DNF_PACKAGES`, then commit and push.
- [ ] **Step 3:** `./bootstrap --dry` prints the plan and changes nothing. Then `./bootstrap`, re-running after any stop it prints. Expected: ends with `[OK]` and the `before-nix` list.
- [ ] **Step 4:** A second `./bootstrap` makes no changes (every step reports already done). Then `nrs` succeeds.
- [ ] **Step 5: Acceptance in a new Windows Terminal tab.**
  - zellij auto-starts, and `ZELLIJ_AUTOSTART=0 zsh` doesn't start it.
  - Ctrl-hjkl crosses nvim splits and zellij panes in both directions.
  - `:checkhealth vim.lsp` in a `.lua` file and in a `.go` file lists an attached client (`lua_ls`, `gopls`). (`:LspInfo` is gone on Neovim 0.12.)
  - `project python313` writes `.envrc`, and the prompt shows `DEV_SHELL`.
  - In a dir with `.prototools` pinning node, `node -v` is the pinned version; outside it, the Nix version. If `activate` leaks outside pinned dirs, apply ticket 08's fallback (per-repo `.envrc`) and tell the user.
  - tmux `prefix + I` installs plugins.
- [ ] **Step 6:** Record the pass/fail results in the commit message of the last `fix(wsl)` commit (or an empty `chore(wsl): acceptance passed` commit). Commit fixes as `fix(wsl): …`.

### Task 9: README and `docs/`

Spec: ticket 15. Written from what Task 8 actually ran.

**Files:**
- Replace: `README.md`
- Create: `docs/zsh.md`, `docs/zellij.md`, `docs/nvim.md`, `docs/tmux.md`, `docs/dev-shells.md`

- [ ] **Step 1: README.** Sections in this order:
  - **Install**: only the `wsl` section for now (systemd and hostname in `wsl.conf`, the manual Windows install of FiraCode and JetBrains Mono Nerd Fonts, `git clone … ~/.dotfiles`, `./bootstrap`, re-run after stops).
  - **Adding a new host**
  - **Layout**: links `GLOSSARY.md` and uses its terms. One line each for git and starship; ghostty and Hyprland lines come in plan 2.
  - **Everyday use**: `nrs`, `nus`, `nfu`, `ngc`, `./bootstrap --dry`, `--clean-backups`.
  - **Where does it go?**
  - **Updating and rolling back**: `nfu` then `nrs`; `home-manager generations` and activating an older one; `ngc` frees space but deletes every old generation, so there is nothing to roll back to afterwards.
  - **Reinstalling a host**: the ticket 14 backup checklist.
  - **Secrets**
  - **Troubleshooting**: `before-nix` collision, WSL without systemd.
- [ ] **Step 2: The five pages,** each opening with `[Home](/README.md) > <Tool>`, covering exactly ticket 15's list. Move the shada/treesitter entries into `nvim.md` only if they reproduce on `wsl`.
- [ ] **Step 3: Check links.** `grep -o '](\([^)]*\))' README.md docs/*.md` shows every relative target exists (`ls` each). `grep -n 'macOS\|Ubuntu\|packer\|Mason' README.md docs/*.md` returns no output.
- [ ] **Step 4: User gate.** The user reads the README. Commit `docs: README and per-tool docs for the Nix port`.
