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

echo "eval checks: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
