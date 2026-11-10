# project: point the current directory at a dev shell from the central flake
# (~/.dotfiles/nix/shells) by writing a two-line .envrc and allowing it.
# Packaged by nix/home/dev/default.nix (writeShellApplication adds the shebang,
# `set -euo pipefail`, and direnv/fzf/jq on PATH; shellcheck runs at build time).

SHELLS_FLAKE="$HOME/.dotfiles/nix/shells"
# Written into .envrc as-is (direnv expands the ~), so it reads naturally.
# shellcheck disable=SC2088
SHELLS_REF="~/.dotfiles/nix/shells"
# nix-direnv only watches the flake's flake.nix/flake.lock; this makes edits to
# envs/*.nix (and any other .nix the flake imports) rebuild the shell too. It
# must come before `use flake`, which checks the watches so far for staleness.
WATCH_LINE="watch_file $SHELLS_REF/*.nix $SHELLS_REF/envs/*.nix"

usage() {
  cat <<EOF
Usage: project [NAME | list | off]

Use a dev shell from $SHELLS_REF in the current directory.

  project           pick a shell with fzf
  project NAME      write .envrc for shell NAME and allow it (e.g. project go)
  project list      list the available shells
  project off       remove the .envrc (only one created by project)
EOF
}

list_shells() {
  local system
  # warn-dirty=false: hide "Git tree is dirty" while ~/.dotfiles has uncommitted changes.
  system=$(nix eval --option warn-dirty false --raw --impure --expr builtins.currentSystem)
  nix eval --option warn-dirty false --json "$SHELLS_FLAKE#devShells.$system" \
    --apply builtins.attrNames | jq -r '.[]'
}

# True if .envrc is one this script manages and may replace or remove: a single
# `use flake …/nix/shells#NAME` line, optionally preceded by WATCH_LINE (older
# versions of this script wrote the use line alone).
is_ours() {
  local rest
  rest=$(grep -vxF "$WATCH_LINE" .envrc || true)
  [[ $(grep -c . <<<"$rest") -le 1 ]] && grep -qE '^use flake [^ ]*nix/shells#[A-Za-z0-9_-]+$' <<<"$rest"
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  list)
    list_shells
    exit 0
    ;;
  off)
    if [[ -f .envrc ]] && is_ours; then
      rm .envrc
      echo "Removed .envrc; the dev shell unloads on your next prompt."
    else
      echo "No .envrc created by project here." >&2
      exit 1
    fi
    exit 0
    ;;
esac

shells=$(list_shells)
if [[ -z ${1:-} ]]; then
  name=$(fzf --height=40% --reverse --prompt="dev shell> " <<<"$shells") || exit 0
else
  name=$1
fi

if ! grep -qxF "$name" <<<"$shells"; then
  echo "Unknown shell '$name'. Available:" >&2
  while IFS= read -r s; do echo "  $s"; done <<<"$shells" >&2
  # Flakes only see git-tracked files, so a new envs/NAME.nix is invisible until added.
  if [[ -f "$SHELLS_FLAKE/envs/$name.nix" ]]; then
    echo "envs/$name.nix exists but isn't tracked by git; run:" >&2
    echo "  git -C ~/.dotfiles add nix/shells/envs/$name.nix" >&2
  fi
  exit 1
fi

if [[ -f .envrc ]] && ! is_ours; then
  echo ".envrc already exists with other content; not overwriting it:" >&2
  sed 's/^/  /' .envrc >&2
  exit 1
fi

printf '%s\nuse flake %s#%s\n' "$WATCH_LINE" "$SHELLS_REF" "$name" >.envrc
direnv allow
echo "Using dev shell '$name' here; it loads on your next prompt (the first load can take a minute)."
