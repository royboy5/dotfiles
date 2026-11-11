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
contains programs.zsh.initContent '-z "$ZSH_EXECUTION_STRING"'
contains programs.zsh.initContent '-t 0 && -t 1'
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

echo "eval checks: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
