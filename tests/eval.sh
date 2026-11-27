#!/usr/bin/env bash
# A && pass || fail is intended (pass never fails); $HOME etc. are literal.
# shellcheck disable=SC2015,SC2016
# Evaluation checks for the home-manager configs. Runs on any machine with Nix
# (nothing is built), so it works from the Mac as well as from a host.
#
# Usage: tests/eval.sh [host]   (default host: wsl)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${1:-wsl}"
CFG="$ROOT/nix#homeConfigurations.\"roy@$HOST\".config"
SYS=""
# unicorn-rx0 is NixOS: home-manager is a module of the system config.
if [[ "$HOST" == unicorn-rx0 ]]; then
    SYS="$ROOT/nix#nixosConfigurations.unicorn-rx0.config"
    CFG="$SYS.home-manager.users.roy"
fi
NIX=(nix --extra-experimental-features "nix-command flakes" eval --no-warn-dirty)
FAILED=0
PASSED=0

pass() { PASSED=$((PASSED + 1)); }
fail() { FAILED=$((FAILED + 1)); echo "FAIL: $*"; }

# eq <attr path under config> <expected raw string>
eq() {
    local got
    got=$("${NIX[@]}" --raw "$CFG.$1" 2>&1) || { fail "$1: eval error: ${got##*$'\n'}"; return; }
    [[ "$got" == "$2" ]] && pass || fail "$1: expected '$2', got '$got'"
}

# json_eq <attr path> <expected JSON>
json_eq() {
    local got
    got=$("${NIX[@]}" --json "$CFG.$1" 2>&1) || { fail "$1: eval error: ${got##*$'\n'}"; return; }
    [[ "$got" == "$2" ]] && pass || fail "$1: expected $2, got $got"
}

# sys_eq / sys_json_eq: like eq / json_eq, but on the NixOS system config.
sys_eq() {
    local got
    got=$("${NIX[@]}" --raw "$SYS.$1" 2>&1) || { fail "sys $1: eval error: ${got##*$'\n'}"; return; }
    [[ "$got" == "$2" ]] && pass || fail "sys $1: expected '$2', got '$got'"
}
sys_json_eq() {
    local got
    got=$("${NIX[@]}" --json "$SYS.$1" 2>&1) || { fail "sys $1: eval error: ${got##*$'\n'}"; return; }
    [[ "$got" == "$2" ]] && pass || fail "sys $1: expected $2, got $got"
}

PKGS=""
pkgs() {
    [[ -n "$PKGS" ]] || PKGS=$("${NIX[@]}" --json "$CFG.home.packages" \
        --apply 'map (p: p.pname or (builtins.parseDrvName p.name).name)' 2>&1)
    echo "$PKGS"
}
has_pkg() { pkgs | grep -q "\"$1\"" && pass || fail "package $1 missing"; }
lacks_pkg() { pkgs | grep -q "\"$1\"" && fail "package $1 must not be installed" || pass; }

# contains <attr path> <substring>   (attr evaluates to a string)
contains() {
    local got
    got=$("${NIX[@]}" --raw "$CFG.$1" 2>&1) || { fail "$1: eval error"; return; }
    [[ "$got" == *"$2"* ]] && pass || fail "$1 does not contain '$2'"
}

# --- Task 1: skeleton -------------------------------------------------------
eq home.username roy
eq home.homeDirectory /home/roy
case "$HOST" in
    unicorn-rx0) json_eq targets.genericLinux.enable false ;;
    wsl)
        json_eq targets.genericLinux.enable true
        json_eq targets.genericLinux.gpu.enable false
        ;;
    *)
        json_eq targets.genericLinux.enable true
        json_eq targets.genericLinux.gpu.enable true
        ;;
esac

# before <attr path> <first substring> <second substring>
before() {
    local got
    got=$("${NIX[@]}" --raw "$CFG.$1" 2>&1) || { fail "$1: eval error"; return; }
    local a="${got%%"$2"*}" b="${got%%"$3"*}"
    [[ "$got" == *"$2"* && "$got" == *"$3"* && ${#a} -lt ${#b} ]] && pass \
        || fail "$1: '$2' must appear before '$3'"
}

# --- Task 2: shell ----------------------------------------------------------
eq home.shellAliases.nfu "nix flake update --flake /home/roy/.dotfiles/nix"
eq home.shellAliases.nus "nix flake update --flake /home/roy/.dotfiles/nix/shells"
case "$HOST" in
    unicorn-rx0)
        eq home.shellAliases.nrs "sudo nixos-rebuild switch --flake /home/roy/.dotfiles/nix#unicorn-rx0"
        eq home.shellAliases.ngc "sudo nix-collect-garbage -d && nix-collect-garbage -d"
        ;;
    *)
        eq home.shellAliases.nrs "home-manager switch --flake /home/roy/.dotfiles/nix#roy@$HOST"
        eq home.shellAliases.ngc "nix-collect-garbage -d && sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage -d"
        ;;
esac
eq home.shellAliases.dot "cd /home/roy/.dotfiles"
eq home.shellAliases.reload "exec zsh"
json_eq programs.zsh.history.size 10000
json_eq programs.zsh.history.save 10000
eq programs.zsh.history.path /home/roy/.local/state/zsh/history
json_eq programs.zsh.enableCompletion false
contains programs.zsh.initContent "zsh-autocomplete.plugin.zsh"
before programs.zsh.initContent "/home/roy/.local/share/zsh" "zsh-autocomplete.plugin.zsh"
contains programs.zsh.initContent "setopt AUTO_CD"
contains programs.zsh.initContent "HIST_REDUCE_BLANKS"
contains programs.zsh.initContent "ZELLIJ_AUTOSTART"
contains programs.zsh.initContent "[[ -o interactive ]]"
contains programs.zsh.initContent '-z "$SSH_CONNECTION"'
contains programs.zsh.initContent '-z "$ZELLIJ"'
contains programs.zsh.initContent '-z "$ZSH_EXECUTION_STRING"'
contains programs.zsh.initContent '-t 0 && -t 1'
before programs.zsh.initContent "local_env.zsh" "ZELLIJ_AUTOSTART"
json_eq programs.starship.enable true

# --- Task 3: cli + git ------------------------------------------------------
for p in bat eza fd fzf ripgrep jq yq-go httpie jless k9s tree curl wget htop \
    git git-lfs delta lazygit; do has_pkg "$p"; done
lacks_pkg glab
eq home.shellAliases.lg lazygit
# grep and find stay the real commands (pasted commands use their flags);
# rg and fd are typed by name.
aliases=$("${NIX[@]}" --json "$CFG.home.shellAliases" --apply builtins.attrNames 2>&1)
for a in grep find; do
    grep -q "\"$a\"" <<< "$aliases" && fail "$a must not be aliased" || pass
done
eq home.shellAliases.catp bat
eq home.sessionVariables.FZF_DEFAULT_COMMAND "rg --files"
contains programs.zsh.initContent "git_current_branch()"
json_eq 'xdg.configFile."git".enable' true

# --- Task 4: tmux + zellij --------------------------------------------------
has_pkg tmux
has_pkg zellij
json_eq 'xdg.configFile."zellij".enable' true
eq home.shellAliases.zdt "zellij action override-layout --apply-only-to-active-tab ~/.dotfiles/configs/zellij/layouts/dev.kdl"
json_eq 'home.file.".tmux.conf".enable' true
# Closing a terminal tab ends its auto-started session instead of leaving it running.
grep -q '^on_force_close "quit"' "$ROOT/configs/zellij/config.kdl" && pass \
    || fail "zellij on_force_close must be quit"

# --- Task 5: nvim -----------------------------------------------------------
for p in neovim tree-sitter lua-language-server typescript-language-server \
    vscode-langservers-extracted stylua prettier black isort; do has_pkg "$p"; done
eq home.sessionVariables.EDITOR nvim
eq home.shellAliases.v nvim
json_eq 'xdg.configFile."nvim".enable' true
grep -rqi mason "$ROOT/configs/nvim" && fail "configs/nvim still mentions Mason" || pass
# A spec's `branch = "x"` must match its lazy-lock.json entry, or lazy.nvim
# installs the wrong branch.
grep -q '"nvim-treesitter": { "branch": "main"' "$ROOT/configs/nvim/lazy-lock.json" && pass \
    || fail "lazy-lock.json pins nvim-treesitter to a branch other than main"

# --- Task 6: toolchains, dev shells, proto ----------------------------------
for p in go gopls gotools delve golangci-lint rustup zig zls uv ruff nodejs pnpm proto project; do has_pkg "$p"; done
lacks_pkg python3
lacks_pkg python3.13-jupyterlab
lacks_pkg moon
eq home.sessionVariables.GOPATH '$HOME/src/go'
sp=$("${NIX[@]}" --json "$CFG.home.sessionPath" 2>&1)
for d in '$HOME/src/go/bin' '$HOME/.cargo/bin' '$HOME/.local/bin'; do
    [[ "$sp" == *"\"$d\""* ]] && pass || fail "sessionPath lacks $d"
done
json_eq programs.direnv.nix-direnv.enable true
json_eq programs.direnv.config.global.hide_env_diff true
contains programs.zsh.initContent "proto activate zsh"
eq home.sessionVariables.PROTO_AUTO_INSTALL true
files=$("${NIX[@]}" --json "$CFG.home.file" --apply builtins.attrNames 2>&1)
[[ "$files" != *'.proto/'* ]] && pass || fail "no proto config file is linked (settings are env vars)"
vars=$("${NIX[@]}" --json "$CFG.home.sessionVariables" --apply builtins.attrNames 2>&1)
[[ "$vars" != *GCP_* && "$vars" != *MOON_TOOLCHAIN_FORCE_GLOBALS* ]] && pass || fail "work or moon vars set: $vars"
shells=$("${NIX[@]}" --json "$ROOT/nix/shells#devShells.x86_64-linux" --apply builtins.attrNames 2>&1)
[[ "$shells" == '["node","node22","node24","python312","python313"]' ]] && pass \
    || fail "dev shells: $shells"

# --- GUI links (plan 2): ghostty and Hyprland on GUI hosts only -------------
LINKS=""
links() {
    [[ -n "$LINKS" ]] || LINKS=$("${NIX[@]}" --json "$CFG.xdg.configFile" --apply builtins.attrNames 2>&1)
    echo "$LINKS"
}
has_link() { links | grep -q "\"$1\"" && pass || fail "$1 must be linked on $HOST"; }
lacks_link() { links | grep -q "\"$1\"" && fail "$1 must not be linked on $HOST" || pass; }
# Plain `home-manager <command>` (news, generations…) finds the flake here.
case "$HOST" in
    unicorn-rx0) lacks_link home-manager ;; # standalone-mode only
    *) has_link home-manager ;;
esac
case "$HOST" in
    wsl)
        lacks_link ghostty
        lacks_link hypr
        ;;
    *)
        has_link ghostty
        has_link hypr
        # The apps themselves come from the system layer (pacman / nixos).
        lacks_pkg ghostty
        lacks_pkg hyprland
        ;;
esac
# Auto-rotate: only wing-zero (a tablet) has an accelerometer.
case "$HOST" in
    wing-zero)
        has_pkg auto-rotate
        has_link autostart/auto-rotate.desktop
        ;;
    *)
        lacks_pkg auto-rotate
        lacks_link autostart/auto-rotate.desktop
        ;;
esac
HYPR="$ROOT/configs/hypr/hyprland.lua"
GHOSTTY="$ROOT/configs/ghostty/config"
grep -qx 'local terminal    = "ghostty"' "$HYPR" 2> /dev/null && pass || fail "hyprland.lua must set the terminal to ghostty"
grep -q 'auto-rotate' "$HYPR" 2> /dev/null && pass || fail "hyprland.lua must start auto-rotate"
[[ -f "$HYPR" ]] && ! grep -q kitty "$HYPR" && pass || fail "hyprland.lua must not mention kitty"
grep -qx 'theme = "TokyoNight Storm"' "$GHOSTTY" 2> /dev/null && pass || fail "ghostty theme must be TokyoNight Storm"
[[ -f "$GHOSTTY" ]] && ! grep -qE '^[^#]*(macos-|super\+)' "$GHOSTTY" && pass || fail "ghostty config has macOS or super+ lines"

if [[ "$HOST" == unicorn-rx0 ]]; then
    sys_json_eq home-manager.useGlobalPkgs true
    sys_json_eq home-manager.useUserPackages true
    sys_eq home-manager.backupFileExtension before-nix
fi

# --- NixOS system layer (unicorn-rx0) ---------------------------------------
if [[ "$HOST" == unicorn-rx0 ]]; then
    sys_names() { # <attr> -> JSON list of package names
        "${NIX[@]}" --json "$SYS.$1" \
            --apply 'map (p: p.pname or (builtins.parseDrvName p.name).name)' 2>&1
    }
    sys_has() { # <attr> <substring of a package name>
        sys_names "$1" | grep -q "$2" && pass || fail "sys $1 lacks a package matching $2"
    }
    sys_json_eq boot.loader.systemd-boot.enable true
    sys_json_eq boot.loader.systemd-boot.configurationLimit 10
    sys_json_eq boot.loader.efi.canTouchEfiVariables true
    sys_json_eq services.power-profiles-daemon.enable true
    sys_json_eq services.tlp.enable false
    sys_json_eq hardware.system76.power-daemon.enable false
    sys_json_eq services.thermald.enable true
    sys_json_eq services.fwupd.enable true
    sys_json_eq hardware.graphics.enable true
    sys_eq networking.hostName unicorn-rx0
    # Timezone follows location (a laptop): nothing pinned, geoclue on.
    sys_json_eq services.automatic-timezoned.enable true
    sys_json_eq time.timeZone null
    sys_json_eq services.geoclue2.enable true
    sys_json_eq services.desktopManager.cosmic.enable true
    sys_json_eq services.displayManager.cosmic-greeter.enable true
    sys_json_eq programs.hyprland.enable true
    sys_json_eq programs.firefox.enable true
    sys_json_eq networking.networkmanager.enable true
    sys_json_eq services.pipewire.enable true
    sys_json_eq services.pipewire.alsa.enable true
    sys_json_eq services.pipewire.pulse.enable true
    sys_json_eq security.rtkit.enable true
    sys_json_eq hardware.bluetooth.enable true
    sys_json_eq networking.firewall.enable true
    sys_json_eq virtualisation.docker.enable true
    sys_json_eq services.openssh.enable true
    sys_json_eq services.openssh.settings.PasswordAuthentication false
    sys_eq services.openssh.settings.PermitRootLogin no
    # Keys are managed by hand in ~/.ssh/authorized_keys (sshd's default);
    # none live in the repo, and the per-user file must stay honored.
    sys_json_eq users.users.roy.openssh.authorizedKeys.keys '[]'
    keyfiles=$("${NIX[@]}" --json "$SYS.services.openssh.authorizedKeysFiles" 2>&1)
    [[ "$keyfiles" == *'"%h/.ssh/authorized_keys"'* ]] && pass \
        || fail "sshd must read ~/.ssh/authorized_keys, got $keyfiles"
    sys_json_eq users.users.roy.isNormalUser true
    sys_eq users.users.roy.shell.shellPath /bin/zsh
    sys_json_eq users.users.roy.extraGroups '["wheel","networkmanager","docker","video","audio"]'
    sys_json_eq users.users.roy.hashedPassword null
    sys_json_eq programs.zsh.enable true
    sys_json_eq programs.zsh.enableCompletion false
    sys_json_eq programs.zsh.enableBashCompletion false
    sys_eq programs.zsh.promptInit ""
    sys_json_eq nix.settings.experimental-features '["nix-command","flakes"]'
    sys_json_eq nix.gc.automatic true
    sys_json_eq nix.gc.dates '["Sun 03:00"]'
    sys_eq nix.gc.options "--delete-older-than 30d"
    sys_json_eq nix.optimise.automatic true
    sys_json_eq programs.nix-ld.enable true
    for p in ghostty bitwarden-desktop wl-clipboard google-chrome; do sys_has environment.systemPackages "\"$p\""; done
    # The unfree allowlist lets Chrome through and nothing else (vscode stands in
    # for "any other unfree package"): drvPath only evaluates when it's allowed.
    PKGS_ATTR="$ROOT/nix#nixosConfigurations.unicorn-rx0.pkgs"
    "${NIX[@]}" --raw "$PKGS_ATTR.google-chrome.drvPath" > /dev/null 2>&1 && pass || fail "google-chrome must be allowed as unfree"
    "${NIX[@]}" --raw "$PKGS_ATTR.vscode.drvPath" > /dev/null 2>&1 && fail "vscode must not be allowed as unfree" || pass
    sys_has fonts.packages fira-code
    sys_has fonts.packages jetbrains-mono
    got=$("${NIX[@]}" --raw "$SYS.system.stateVersion" 2>&1)
    [[ "$got" =~ ^[0-9][0-9]\.[0-9][0-9]$ ]] && pass || fail "system.stateVersion: '$got'"
    # Two states: before the machine exists the hardware assertion must fail with
    # the instruction; once its hardware file is committed, nothing may fail.
    if [[ -f "$ROOT/nix/nixos/hardware/unicorn-rx0.nix" ]]; then
        got=$("${NIX[@]}" --json "$SYS.assertions" --apply 'a: builtins.any (x: !x.assertion) a' 2>&1)
        [[ "$got" == false ]] && pass || fail "a NixOS assertion fails: $got"
    else
        got=$("${NIX[@]}" --json "$SYS.assertions" --apply \
            'a: builtins.any (x: !x.assertion && builtins.match ".*nixos-generate-config --show-hardware-config.*" x.message != null) a' 2>&1)
        [[ "$got" == true ]] && pass || fail "missing-hardware assertion absent: $got"
    fi
fi

echo "eval checks: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
