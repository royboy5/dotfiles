#!/usr/bin/env bash
# Steps shared by every host. Each one checks the machine's own state and skips
# what's already done, so ./bootstrap can be re-run at any point.

: "${NIX_DAEMON_PROFILE:=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh}"
: "${NIX_CONF:=/etc/nix/nix.conf}"
: "${NIX_DAEMON_UNIT:=/etc/systemd/system/nix-daemon.service}"
: "${KERNEL_CMDLINE:=/etc/kernel/cmdline}"
: "${GRUB_DEFAULTS:=/etc/default/grub}"
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

# Sets BOOTSTRAP_DRY (not exported: home-manager treats any DRY_RUN as a dry run), HOST_OVERRIDE and CLEAN_BACKUPS for main.
# shellcheck disable=SC2034
parse_args() {
    BOOTSTRAP_DRY=0
    HOST_OVERRIDE=""
    CLEAN_BACKUPS=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry) BOOTSTRAP_DRY=1 ;;
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

# Flakes inside a git repo only see tracked files (any file under nix/, not
# just .nix: scripts read with builtins.readFile count too).
check_untracked() {
    local untracked
    untracked=$(git -C "$DOTFILES_ROOT" ls-files --others --exclude-standard -- nix/)
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
        # An install made some other way (e.g. while WSL had systemd off) has no
        # daemon service, so flakes and home-manager can't work against it.
        if [[ ! -e "$NIX_DAEMON_UNIT" ]]; then
            log_error "Nix is installed but has no nix-daemon service ($NIX_DAEMON_UNIT)."
            log_error "Remove it (README: Troubleshooting, 'no nix-daemon service'), then re-run."
            return 1
        fi
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
    # Start a new line if the file's last line has no newline.
    local line="$FLAKES_LINE"
    [[ -s "$NIX_CONF" && -n "$(tail -c1 "$NIX_CONF")" ]] && line=$'\n'"$line"
    if [[ "${BOOTSTRAP_DRY:-0}" == "1" ]]; then
        execute sudo tee -a "$NIX_CONF" "<<< '$FLAKES_LINE'"
    else
        echo "$line" | sudo tee -a "$NIX_CONF" > /dev/null
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
# because -b fails once a backup with that name exists. --dry only builds,
# without a ./result link.
hm_switch() {
    local ref="$DOTFILES_ROOT/nix#$REPO_USER@$1" action=switch opts=()
    [[ "${BOOTSTRAP_DRY:-0}" == "1" ]] && { action=build; opts=(--no-out-link); }
    if command -v home-manager &> /dev/null; then
        log_info "home-manager $action ($ref)..."
        home-manager "$action" "${opts[@]}" --flake "$ref"
    else
        log_info "First home-manager $action ($ref)..."
        # A dry run on a fresh host never installed Nix, so there's nothing to
        # build with: show the first switch instead.
        if [[ "$action" == build ]] && ! command -v nix &> /dev/null; then
            execute nix "${NIX_FLAGS[@]}" run home-manager/master -- switch -b before-nix --flake "$ref"
            return 0
        fi
        [[ "$action" == switch ]] && opts=(-b before-nix)
        nix "${NIX_FLAGS[@]}" run home-manager/master -- "$action" "${opts[@]}" --flake "$ref"
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

# ensure_service <unit>...: enable and start each unit that isn't enabled yet.
ensure_service() {
    local unit
    for unit in "$@"; do
        if systemctl is-enabled --quiet "$unit" 2> /dev/null; then
            log_success "$unit is enabled."
        else
            execute sudo systemctl enable --now "$unit"
        fi
    done
}

# ensure_group <group>: add the user to it. Checked against the group database,
# not `id -nG`, which only changes after logging in again.
ensure_group() {
    local group="$1" members
    # The group may not exist yet (a --dry run on a fresh host never installed
    # the package that creates it).
    members=$(getent group "$group" | cut -d: -f4 || true)
    if [[ ",$members," == *",$USER,"* ]]; then
        log_success "$USER is in the $group group."
        return 0
    fi
    execute sudo usermod -aG "$group" "$USER"
    log_warn "Log out and back in for the $group group to apply."
}

# home-manager's GPU module (targets.genericLinux.gpu) links the Nix GL/Vulkan
# drivers to /run/opengl-driver. sudo doesn't see the user's PATH, so it gets
# the absolute store path. Idempotent: safe after every switch.
ensure_gpu_setup() {
    local setup
    if ! setup=$(command -v non-nixos-gpu-setup); then
        log_warn "non-nixos-gpu-setup isn't on PATH; skipping the GPU setup (expected with --dry, which doesn't activate; otherwise open a new terminal and re-run)."
        return 0
    fi
    execute sudo "$(readlink -f "$setup")"
}

# ensure_kernel_param <option>: add a kernel command-line option for the next
# boot. systemd-boot (EndeavourOS's default) reads /etc/kernel/cmdline when
# reinstall-kernels rebuilds the boot entries; GRUB reads
# GRUB_CMDLINE_LINUX_DEFAULT when grub-mkconfig regenerates grub.cfg.
ensure_kernel_param() {
    local param="$1" line new
    if [[ -f "$KERNEL_CMDLINE" ]]; then
        line=$(< "$KERNEL_CMDLINE")
        if [[ " $line " == *" $param "* ]]; then
            log_success "Kernel option $param is set."
            return 0
        fi
        _sudo_write "$KERNEL_CMDLINE" "${line:+$line }$param"
        execute sudo reinstall-kernels
    elif [[ -f "$GRUB_DEFAULTS" ]]; then
        local re='^(GRUB_CMDLINE_LINUX_DEFAULT=["'\''])(.*)(["'\''])$' found=0
        new=""
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ $re ]]; then
                found=1
                if [[ " ${BASH_REMATCH[2]} " == *" $param "* ]]; then
                    log_success "Kernel option $param is set."
                    return 0
                fi
                line="${BASH_REMATCH[1]}${BASH_REMATCH[2]:+${BASH_REMATCH[2]} }$param${BASH_REMATCH[3]}"
            fi
            new+="$line"$'\n'
        done < "$GRUB_DEFAULTS"
        if [[ "$found" == 0 ]]; then
            log_warn "No GRUB_CMDLINE_LINUX_DEFAULT line in $GRUB_DEFAULTS; add $param to the kernel options by hand."
            return 0
        fi
        _sudo_write "$GRUB_DEFAULTS" "${new%$'\n'}"
        execute sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
        log_warn "Found neither $KERNEL_CMDLINE (systemd-boot) nor $GRUB_DEFAULTS (GRUB); add $param to the kernel options by hand."
        return 0
    fi
    log_warn "Reboot for the kernel option $param to apply."
}

# _sudo_write <file> <content>: replace a root-owned file's content.
_sudo_write() {
    if [[ "${BOOTSTRAP_DRY:-0}" == "1" ]]; then
        execute sudo tee "$1" "<<< '$2'"
    else
        printf '%s\n' "$2" | sudo tee "$1" > /dev/null
    fi
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
        log_warn "rustup isn't on PATH; skipping the toolchain (expected with --dry, which doesn't activate; otherwise open a new terminal and re-run)."
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
