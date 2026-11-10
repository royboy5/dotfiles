#!/usr/bin/env bash
# Evaluation checks for the home-manager configs. Runs on any machine with Nix
# (nothing is built), so it works from the Mac as well as from a host.
#
# Usage: tests/eval.sh [host]   (default host: wsl)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${1:-wsl}"
CFG="$ROOT/nix#homeConfigurations.\"roy@$HOST\".config"
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
json_eq targets.genericLinux.enable true
json_eq targets.genericLinux.gpu.enable false

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
eq home.shellAliases.nrs "home-manager switch --flake /home/roy/.dotfiles/nix#roy@wsl"
eq home.shellAliases.ngc "nix-collect-garbage -d && sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage -d"
eq home.shellAliases.dot "cd /home/roy/.dotfiles"
eq home.shellAliases.reload "exec zsh"
json_eq programs.zsh.history.size 10000
json_eq programs.zsh.history.save 10000
eq programs.zsh.history.path /home/roy/.local/state/zsh/history
json_eq programs.zsh.enableCompletion false
contains programs.zsh.initContent "zsh-autocomplete.plugin.zsh"
contains programs.zsh.initContent "setopt AUTO_CD"
contains programs.zsh.initContent "HIST_REDUCE_BLANKS"
contains programs.zsh.initContent "ZELLIJ_AUTOSTART"
contains programs.zsh.initContent "[[ -o interactive ]]"
contains programs.zsh.initContent '-z "$SSH_CONNECTION"'
contains programs.zsh.initContent '-z "$ZELLIJ"'
before programs.zsh.initContent "local_env.zsh" "ZELLIJ_AUTOSTART"
json_eq programs.starship.enable true

# --- Task 3: cli + git ------------------------------------------------------
for p in bat eza fd fzf ripgrep jq yq-go httpie jless k9s tree curl wget htop \
    git git-lfs delta lazygit; do has_pkg "$p"; done
lacks_pkg glab
eq home.shellAliases.lg lazygit
eq home.shellAliases.find fd
eq home.shellAliases.catp bat
eq home.sessionVariables.FZF_DEFAULT_COMMAND "rg --files"
contains programs.zsh.initContent "git_current_branch()"
json_eq 'xdg.configFile."git".enable' true

# --- Task 4: tmux + zellij --------------------------------------------------
has_pkg tmux
has_pkg zellij
json_eq 'xdg.configFile."zellij".enable' true
json_eq 'home.file.".tmux.conf".enable' true
attrs=$("${NIX[@]}" --json "$CFG.xdg.configFile" --apply builtins.attrNames 2>&1)
[[ "$attrs" != *'"ghostty"'* ]] && pass || fail "ghostty must not be linked on $HOST"

echo "eval checks: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
