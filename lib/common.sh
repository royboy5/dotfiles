#!/usr/bin/env bash
# Steps shared by every host. Each one checks the machine's own state and skips
# what's already done, so ./bootstrap can be re-run at any point.

: "${NIX_DAEMON_PROFILE:=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh}"
: "${NIX_CONF:=/etc/nix/nix.conf}"
NIX_INSTALLER_URL="https://artifacts.nixos.org/nix-installer"
FLAKES_LINE="experimental-features = nix-command flakes"
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")
REPO_USER="roy"

usage() {
    cat <<USAGE
Usage: ./bootstrap [--dry] [--host <name>] [--clean-backups]

Set up this machine from the repo: system packages, Nix and home-manager
(or the NixOS system). Safe to re-run; finished steps are skipped.

  --dry             print system changes instead of making them; build without activating
  --host <name>     use this host instead of \`hostname -s\` (known: ${KNOWN_HOSTS[*]})
  --clean-backups   delete the *.before-nix files left by the first switch
USAGE
}

# Sets DRY_RUN, HOST_OVERRIDE and CLEAN_BACKUPS for main.
# shellcheck disable=SC2034
parse_args() {
    DRY_RUN=0
    HOST_OVERRIDE=""
    CLEAN_BACKUPS=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry) DRY_RUN=1 ;;
            --host)
                [[ -n "${2:-}" ]] || { log_error "--host needs a host name"; return 2; }
                HOST_OVERRIDE="$2"
                shift
                ;;
            --clean-backups) CLEAN_BACKUPS=1 ;;
            -h | --help) usage; exit 0 ;;
            *) log_error "Unknown option: $1"; usage >&2; return 2 ;;
        esac
        shift
    done
    export DRY_RUN
}

# Prints the host to set up: --host, else the short hostname.
resolve_host() {
    local host="${HOST_OVERRIDE:-$(hostname -s)}" known
    for known in "${KNOWN_HOSTS[@]}"; do
        if [[ "$host" == "$known" ]]; then
            echo "$host"
            return 0
        fi
    done
    log_error "Unknown host '$host'. Known hosts: ${KNOWN_HOSTS[*]}. Use --host <name>."
    return 1
}

check_user() {
    if [[ "$(id -u)" == "0" ]]; then
        log_error "Don't run this as root; run it as $REPO_USER (it uses sudo where needed)."
        return 1
    fi
    if [[ "$USER" != "$REPO_USER" ]]; then
        log_error "Every host's user is '$REPO_USER', but this is '$USER'."
        return 1
    fi
}

# The live config links (mkOutOfStoreSymlink) point at ~/.dotfiles.
check_repo_path() {
    if [[ "$DOTFILES_ROOT" != "$HOME/.dotfiles" ]]; then
        log_error "The repo must be cloned at ~/.dotfiles (it is at $DOTFILES_ROOT)."
        return 1
    fi
}

# Flakes inside a git repo only see tracked files.
check_untracked() {
    local untracked
    untracked=$(git -C "$DOTFILES_ROOT" ls-files --others --exclude-standard -- 'nix/*.nix' 'nix/**/*.nix')
    if [[ -n "$untracked" ]]; then
        log_error "These files are not tracked by git, so Nix won't see them:"
        echo "        ${untracked//$'\n'/$'\n'        }" >&2
        echo "        Run: git -C \"$DOTFILES_ROOT\" add nix/" >&2
        return 1
    fi
}

# Puts nix (and, after the first switch, home-manager) on PATH for this shell.
load_nix_env() {
    if [[ -f "$NIX_DAEMON_PROFILE" ]]; then
        set +u
        # shellcheck disable=SC1090
        source "$NIX_DAEMON_PROFILE"
        set -u
    fi
    return 0
}

# ensure_nix [planner args...]: the NixOS community installer. Hosts pass a
# planner when they need one (Bazzite: ostree --persistence=/var/lib/nix).
ensure_nix() {
    if command -v nix &> /dev/null; then
        log_success "Nix is installed ($(nix --version 2> /dev/null))."
        return 0
    fi
    log_info "Installing Nix..."
    execute bash -c "curl -sSfL $NIX_INSTALLER_URL | sh -s -- install $*"
    load_nix_env
}

ensure_flakes() {
    if grep -qE '^\s*(extra-)?experimental-features\s*=.*flakes' "$NIX_CONF" 2> /dev/null; then
        log_success "Flakes are enabled in $NIX_CONF."
        return 0
    fi
    log_info "Enabling flakes in $NIX_CONF..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        execute sudo tee -a "$NIX_CONF" "<<< '$FLAKES_LINE'"
    else
        echo "$FLAKES_LINE" | sudo tee -a "$NIX_CONF" > /dev/null
    fi
    execute sudo systemctl restart nix-daemon
}

# Create/update flake.lock as the user, so no later sudo step creates it as root.
lock_flake() {
    log_info "Locking flake inputs..."
    execute nix "${NIX_FLAGS[@]}" flake lock "$DOTFILES_ROOT/nix"
}

# hm_switch <host>: standalone home-manager. The first switch (home-manager not
# installed yet) moves clashing files aside as *.before-nix; later runs don't,
# because -b fails once a backup with that name exists. --dry only builds.
hm_switch() {
    local ref="$DOTFILES_ROOT/nix#$REPO_USER@$1" action=switch
    [[ "${DRY_RUN:-0}" == "1" ]] && action=build
    if command -v home-manager &> /dev/null; then
        log_info "home-manager $action ($ref)..."
        home-manager "$action" --flake "$ref"
    else
        log_info "First home-manager $action ($ref)..."
        local backup=()
        [[ "$action" == switch ]] && backup=(-b before-nix)
        nix "${NIX_FLAGS[@]}" run home-manager/master -- "$action" "${backup[@]}" --flake "$ref"
    fi
}

# The distro's zsh stays the login shell; home-manager only writes its config.
ensure_login_shell() {
    local want="$1" current
    current=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current" == "$want" ]]; then
        log_success "Login shell is $want."
        return 0
    fi
    log_info "Changing the login shell from $current to $want..."
    execute sudo usermod -s "$want" "$USER"
}

# tmux plugins are managed by TPM; install them with prefix + I.
ensure_tpm() {
    local dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$dir" ]]; then
        log_success "TPM is installed."
        return 0
    fi
    execute git clone https://github.com/tmux-plugins/tpm "$dir"
}

# rustup comes from Nix; the toolchain itself lives in ~/.rustup.
ensure_rustup() {
    if ! command -v rustup &> /dev/null; then
        log_warn "rustup isn't on PATH yet (first --dry run?); skipping the toolchain."
        return 0
    fi
    if rustup default 2> /dev/null | grep -q .; then
        log_success "rustup has a default toolchain."
        return 0
    fi
    execute rustup default stable
    execute rustup component add rust-analyzer
}

_find_backups() {
    find "$HOME" -maxdepth 1 -name '*.before-nix' 2> /dev/null
    find "$HOME/.config" -maxdepth 2 -name '*.before-nix' 2> /dev/null
    find /etc -maxdepth 2 -name '*.before-nix' 2> /dev/null
    return 0
}

list_backups() {
    local files
    files=$(_find_backups)
    if [[ -z "$files" ]]; then
        log_success "No *.before-nix backups."
        return 0
    fi
    log_info "Files moved aside by the first switch (delete with ./bootstrap --clean-backups):"
    echo "        ${files//$'\n'/$'\n'        }"
}

clean_backups() {
    local files answer f
    files=$(_find_backups)
    if [[ -z "$files" ]]; then
        log_success "No *.before-nix backups."
        return 0
    fi
    echo "$files"
    read -r -p "Delete these files? [y/N] " answer
    [[ "$answer" == [yY] ]] || { log_info "Kept them."; return 0; }
    while IFS= read -r f; do
        if [[ "$f" == /etc/* ]]; then
            execute sudo rm -f "$f"
        else
            execute rm -f "$f"
        fi
    done <<< "$files"
    log_success "Deleted."
}
