#!/usr/bin/env bats
# Unit tests for ./bootstrap. Commands with side effects are replaced by stubs
# on PATH that record their arguments in $CALLS.
#
# Run: nix shell nixpkgs#bats -c bats tests/

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    TMP="$(mktemp -d)"
    STUBS="$TMP/stubs"
    CALLS="$TMP/calls"
    mkdir -p "$STUBS"
    : > "$CALLS"
    export CALLS

    # A stub prints nothing, records "<name> <args>" and succeeds.
    for cmd in sudo nix home-manager dnf systemctl usermod rustup; do
        stub "$cmd"
    done
    stub_out hostname "DESKTOP-AB12"
    stub_out id "1000"

    export HOME="$TMP/home"
    mkdir -p "$HOME/.config"
    export USER=roy
    export PATH="$STUBS:$PATH"

    # shellcheck disable=SC1091
    source "$ROOT/bootstrap"
    DOTFILES_ROOT="$HOME/.dotfiles"
    NIX_DAEMON_UNIT="$TMP/nix-daemon.service"
    touch "$NIX_DAEMON_UNIT"
}

teardown() {
    rm -rf "$TMP"
}

stub() {
    printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALLS"\n' "$1" > "$STUBS/$1"
    chmod +x "$STUBS/$1"
}

stub_out() {
    printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALLS"\necho "%s"\n' "$1" "$2" > "$STUBS/$1"
    chmod +x "$STUBS/$1"
}

unstub() {
    rm -f "$STUBS/$1"
}

# --- parse_args ---------------------------------------------------------------

@test "parse_args rejects an unknown flag with exit 2" {
    run parse_args --bogus
    [ "$status" -eq 2 ]
    [[ "$output" == *"--bogus"* ]]
}

@test "parse_args sets dry run, host override and clean-backups" {
    parse_args --dry --host wsl --clean-backups
    [ "$BOOTSTRAP_DRY" = 1 ]
    [ "$HOST_OVERRIDE" = wsl ]
    [ "$CLEAN_BACKUPS" = 1 ]
}

# --- resolve_host -------------------------------------------------------------

@test "resolve_host fails for an unknown hostname and lists the known hosts" {
    run resolve_host
    [ "$status" -eq 1 ]
    [[ "$output" == *"DESKTOP-AB12"* ]]
    [[ "$output" == *"Known hosts: wsl"* ]]
    [[ "$output" == *"--host"* ]]
}

@test "resolve_host uses --host whatever the hostname is" {
    HOST_OVERRIDE=wsl
    run resolve_host
    [ "$status" -eq 0 ]
    [ "$output" = wsl ]
}

@test "resolve_host rejects an unknown --host" {
    HOST_OVERRIDE=nope
    run resolve_host
    [ "$status" -eq 1 ]
}

@test "resolve_host accepts a known hostname" {
    stub_out hostname "wsl"
    run resolve_host
    [ "$output" = wsl ]
}

# --- check_user ---------------------------------------------------------------

@test "check_user refuses to run as root" {
    stub_out id "0"
    run check_user
    [ "$status" -eq 1 ]
    [[ "$output" == *"root"* ]]
}

@test "check_user refuses a user other than roy" {
    USER=reng
    run check_user
    [ "$status" -eq 1 ]
    [[ "$output" == *"roy"* ]]
}

@test "check_user accepts roy" {
    run check_user
    [ "$status" -eq 0 ]
}

# --- check_repo_path ----------------------------------------------------------

@test "check_repo_path refuses a clone outside ~/.dotfiles" {
    DOTFILES_ROOT="$TMP/elsewhere"
    run check_repo_path
    [ "$status" -eq 1 ]
    [[ "$output" == *".dotfiles"* ]]
}

@test "check_repo_path accepts ~/.dotfiles" {
    run check_repo_path
    [ "$status" -eq 0 ]
}

# --- check_untracked ----------------------------------------------------------

@test "check_untracked refuses untracked nix files" {
    DOTFILES_ROOT="$TMP/repo"
    mkdir -p "$DOTFILES_ROOT/nix"
    git -C "$DOTFILES_ROOT" init -q
    touch "$DOTFILES_ROOT/nix/foo.nix"
    run check_untracked
    [ "$status" -eq 1 ]
    [[ "$output" == *"nix/foo.nix"* ]]
}

@test "check_untracked passes once the files are tracked" {
    DOTFILES_ROOT="$TMP/repo"
    mkdir -p "$DOTFILES_ROOT/nix"
    git -C "$DOTFILES_ROOT" init -q
    touch "$DOTFILES_ROOT/nix/foo.nix"
    git -C "$DOTFILES_ROOT" add nix
    run check_untracked
    [ "$status" -eq 0 ]
}

@test "check_untracked refuses untracked non-nix files under nix/" {
    DOTFILES_ROOT="$TMP/repo"
    mkdir -p "$DOTFILES_ROOT/nix/home/scripts"
    git -C "$DOTFILES_ROOT" init -q
    touch "$DOTFILES_ROOT/nix/home/scripts/new.sh"
    run check_untracked
    [ "$status" -eq 1 ]
    [[ "$output" == *"new.sh"* ]]
}

# --- execute ------------------------------------------------------------------

@test "execute only prints the command in dry-run mode" {
    BOOTSTRAP_DRY=1
    run execute touch "$TMP/f"
    [ ! -e "$TMP/f" ]
    [[ "$output" == *"[DRY] Would run: touch $TMP/f"* ]]
}

@test "execute runs the command normally" {
    BOOTSTRAP_DRY=0
    execute touch "$TMP/f"
    [ -e "$TMP/f" ]
}

# --- load_nix_env -------------------------------------------------------------

@test "load_nix_env sources the daemon profile when it exists" {
    NIX_DAEMON_PROFILE="$TMP/nix-daemon.sh"
    echo 'export LOADED_NIX=yes' > "$NIX_DAEMON_PROFILE"
    load_nix_env
    [ "$LOADED_NIX" = yes ]
}

@test "load_nix_env is a no-op without Nix" {
    NIX_DAEMON_PROFILE="$TMP/missing.sh"
    run load_nix_env
    [ "$status" -eq 0 ]
}

# --- ensure_nix ---------------------------------------------------------------

@test "ensure_nix skips the installer when nix is on PATH" {
    run ensure_nix
    [ "$status" -eq 0 ]
    ! grep -q nix-installer "$CALLS"
}

@test "ensure_nix stops when an existing Nix has no daemon service" {
    NIX_DAEMON_UNIT="$TMP/missing.service"
    run ensure_nix
    [ "$status" -eq 1 ]
    [[ "$output" == *"nix-daemon"* ]]
    [[ "$output" == *"README"* ]]
    ! grep -q nix-installer "$CALLS"
}

@test "ensure_nix runs the installer with host-specific arguments when nix is missing" {
    unstub nix
    PATH="$STUBS:/usr/bin:/bin"
    stub curl
    BOOTSTRAP_DRY=1
    run ensure_nix ostree --persistence=/var/lib/nix
    [[ "$output" == *"https://artifacts.nixos.org/nix-installer"* ]]
    [[ "$output" == *"install ostree --persistence=/var/lib/nix"* ]]
}

# --- ensure_flakes ------------------------------------------------------------

@test "ensure_flakes leaves a config that already enables flakes alone" {
    NIX_CONF="$TMP/nix.conf"
    echo "experimental-features = nix-command flakes" > "$NIX_CONF"
    run ensure_flakes
    [ "$status" -eq 0 ]
    ! grep -q systemctl "$CALLS"
}

@test "ensure_flakes adds the setting and restarts the daemon" {
    NIX_CONF="$TMP/nix.conf"
    : > "$NIX_CONF"
    ensure_flakes
    grep -q "sudo tee -a $NIX_CONF" "$CALLS"
    grep -q "sudo systemctl restart nix-daemon" "$CALLS"
}

@test "ensure_flakes keeps an unterminated last line intact" {
    NIX_CONF="$TMP/nix.conf"
    printf 'build-users-group = nixbld' > "$NIX_CONF"
    printf '#!/usr/bin/env bash\necho "sudo $*" >> "$CALLS"\n"$@"\n' > "$STUBS/sudo"
    stub systemctl
    ensure_flakes
    [ "$(tail -n 1 "$NIX_CONF")" == "$FLAKES_LINE" ]
    [ "$(grep -c '^build-users-group = nixbld$' "$NIX_CONF")" -eq 1 ]
}

# --- hm_switch ----------------------------------------------------------------

@test "hm_switch backs up existing files on the first switch only" {
    unstub home-manager
    PATH="$STUBS:/usr/bin:/bin"
    hm_switch wsl
    grep -q -- "nix .*home-manager/master -- switch -b before-nix --flake $DOTFILES_ROOT/nix#roy@wsl" "$CALLS"
}

@test "hm_switch uses the installed home-manager without -b afterwards" {
    hm_switch wsl
    grep -q "^home-manager switch --flake $DOTFILES_ROOT/nix#roy@wsl" "$CALLS"
    ! grep -q -- "-b before-nix" "$CALLS"
}

@test "hm_switch doesn't leak a dry-run variable into home-manager" {
    printf '#!/usr/bin/env bash\necho "hm-env DRY_RUN=${DRY_RUN-unset}" >> "$CALLS"\n' > "$STUBS/home-manager"
    chmod +x "$STUBS/home-manager"
    parse_args
    hm_switch wsl
    grep -q "hm-env DRY_RUN=unset" "$CALLS"
}

@test "hm_switch dry run on a host without Nix only prints the first switch" {
    unstub nix
    unstub home-manager
    PATH="$STUBS:/usr/bin:/bin"
    BOOTSTRAP_DRY=1
    run hm_switch wsl
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY] Would run:"*"switch -b before-nix --flake $DOTFILES_ROOT/nix#roy@wsl"* ]]
}

@test "hm_switch dry run doesn't leave a result link" {
    BOOTSTRAP_DRY=1
    hm_switch wsl
    grep -q "^home-manager build --no-out-link" "$CALLS"
    : > "$CALLS"
    unstub home-manager
    PATH="$STUBS:/usr/bin:/bin"
    hm_switch wsl
    grep -q -- "home-manager/master -- build --no-out-link" "$CALLS"
}

@test "hm_switch only builds in dry-run mode" {
    BOOTSTRAP_DRY=1
    hm_switch wsl
    grep -q "^home-manager build --no-out-link --flake $DOTFILES_ROOT/nix#roy@wsl" "$CALLS"
    ! grep -q "switch" "$CALLS"
}

# --- ensure_login_shell -------------------------------------------------------

@test "ensure_login_shell changes the shell when it differs" {
    stub_out getent "roy:x:1000:1000::/home/roy:/bin/bash"
    ensure_login_shell /usr/bin/zsh
    grep -q "sudo usermod -s /usr/bin/zsh roy" "$CALLS"
}

@test "ensure_login_shell does nothing when it already matches" {
    stub_out getent "roy:x:1000:1000::/home/roy:/usr/bin/zsh"
    ensure_login_shell /usr/bin/zsh
    ! grep -q usermod "$CALLS"
}

# --- ensure_tpm / ensure_rustup ----------------------------------------------

@test "ensure_tpm clones TPM when it's missing" {
    stub git
    ensure_tpm
    grep -q "git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm" "$CALLS"
}

@test "ensure_tpm skips an existing clone" {
    mkdir -p "$HOME/.tmux/plugins/tpm"
    stub git
    ensure_tpm
    ! grep -q "git clone" "$CALLS"
}

@test "ensure_rustup sets stable and adds rust-analyzer when no default is set" {
    stub_out rustup ""
    ensure_rustup
    grep -q "rustup default stable" "$CALLS"
    grep -q "rustup component add rust-analyzer" "$CALLS"
}

@test "ensure_rustup leaves an existing default alone" {
    stub_out rustup "stable-x86_64-unknown-linux-gnu (default)"
    ensure_rustup
    ! grep -q "rustup default stable" "$CALLS"
}

# --- backups ------------------------------------------------------------------

@test "list_backups finds before-nix files" {
    touch "$HOME/.zshrc.before-nix"
    mkdir -p "$HOME/.config/git"
    touch "$HOME/.config/git/config.before-nix"
    run list_backups
    [[ "$output" == *".zshrc.before-nix"* ]]
    [[ "$output" == *"git/config.before-nix"* ]]
}

@test "clean_backups keeps the files when the answer is no" {
    touch "$HOME/.zshrc.before-nix"
    run clean_backups <<< "n"
    [ -e "$HOME/.zshrc.before-nix" ]
}

@test "clean_backups deletes the files when the answer is yes" {
    touch "$HOME/.zshrc.before-nix"
    run clean_backups <<< "y"
    [ ! -e "$HOME/.zshrc.before-nix" ]
}

# --- main -------------------------------------------------------------------

@test "main refuses root before cleaning backups" {
    stub_out id "0"
    touch "$HOME/.zshrc.before-nix"
    run main --clean-backups <<< "y"
    [ "$status" -eq 1 ]
    [ -e "$HOME/.zshrc.before-nix" ]
}

# --- host_wsl -----------------------------------------------------------------

@test "host_wsl stops with instructions when systemd isn't running" {
    SYSTEMD_DIR="$TMP/no-systemd"
    run host_wsl
    [ "$status" -eq 1 ]
    [[ "$output" == *"systemd=true"* ]]
    [[ "$output" == *"wsl --shutdown"* ]]
    ! grep -q dnf "$CALLS"
}

@test "host_wsl installs the dnf list, then switches roy@wsl" {
    SYSTEMD_DIR="$TMP"
    NIX_CONF="$TMP/nix.conf"
    echo "experimental-features = nix-command flakes" > "$NIX_CONF"
    stub_out getent "roy:x:1000:1000::/home/roy:/usr/bin/zsh"
    stub git
    host_wsl
    grep -q "sudo dnf install -y zsh" "$CALLS"
    grep -q "home-manager switch --flake $DOTFILES_ROOT/nix#roy@wsl" "$CALLS"
    ! grep -q "non-nixos-gpu-setup" "$CALLS"
}

# --- wing-zero helpers ----------------------------------------------------------

# getent stub: "passwd" prints roy's entry with zsh, "group" prints $1.
stub_getent() {
    printf '#!/usr/bin/env bash\necho "getent $*" >> "$CALLS"\ncase "$1" in\n  passwd) echo "roy:x:1000:1000::/home/roy:/usr/bin/zsh" ;;\n  group) echo "%s" ;;\nesac\n' "$1" > "$STUBS/getent"
    chmod +x "$STUBS/getent"
}

@test "resolve_host lists wing-zero for an unknown hostname" {
    run resolve_host
    [ "$status" -eq 1 ]
    [[ "$output" == *"wing-zero"* ]]
}

@test "ensure_service enables only units that aren't enabled" {
    printf '#!/usr/bin/env bash\necho "systemctl $*" >> "$CALLS"\n[[ "$1" == is-enabled && "$*" == *docker.service* ]] && exit 1\nexit 0\n' > "$STUBS/systemctl"
    chmod +x "$STUBS/systemctl"
    ensure_service docker.service reflector.timer
    [ "$(grep -c 'enable --now' "$CALLS")" -eq 1 ]
    grep -q "sudo systemctl enable --now docker.service" "$CALLS"
}

@test "ensure_group adds roy when the group database lacks him" {
    stub_getent "docker:x:970:"
    run ensure_group docker
    [ "$status" -eq 0 ]
    grep -q "sudo usermod -aG docker roy" "$CALLS"
    [[ "$output" == *"Log out"* ]]
}

@test "ensure_group skips when getent lists roy" {
    stub_getent "docker:x:970:alice,roy"
    run ensure_group docker
    [ "$status" -eq 0 ]
    ! grep -q usermod "$CALLS"
}

@test "ensure_gpu_setup runs the absolute store path with sudo" {
    stub non-nixos-gpu-setup
    ensure_gpu_setup
    grep -q "^sudo $(readlink -f "$STUBS")/non-nixos-gpu-setup$" "$CALLS"
}

@test "ensure_gpu_setup warns and skips when it isn't installed" {
    run ensure_gpu_setup
    [ "$status" -eq 0 ]
    ! grep -q "^sudo" "$CALLS"
    [[ "$output" == *"--dry"* ]]
}

@test "host_wing_zero installs the pacman list, then switches roy@wing-zero" {
    NIX_CONF="$TMP/nix.conf"
    echo "experimental-features = nix-command flakes" > "$NIX_CONF"
    stub_getent "docker:x:970:roy"
    stub git
    host_wing_zero
    local pac
    pac=$(grep -n "sudo pacman -Syu --needed --noconfirm" "$CALLS" | cut -d: -f1)
    [ -n "$pac" ]
    for p in cosmic hyprland ghostty ttf-firacode-nerd; do
        grep "sudo pacman" "$CALLS" | grep -qw "$p"
    done
    local hm
    hm=$(grep -n "home-manager switch --flake $DOTFILES_ROOT/nix#roy@wing-zero" "$CALLS" | cut -d: -f1)
    [ -n "$hm" ]
    [ "$pac" -lt "$hm" ]
}

@test "host_wing_zero runs the GPU setup after the switch" {
    NIX_CONF="$TMP/nix.conf"
    echo "experimental-features = nix-command flakes" > "$NIX_CONF"
    stub_getent "docker:x:970:roy"
    stub git
    stub non-nixos-gpu-setup
    host_wing_zero
    local hm gpu
    hm=$(grep -n "home-manager switch" "$CALLS" | cut -d: -f1)
    gpu=$(grep -n "^sudo $(readlink -f "$STUBS")/non-nixos-gpu-setup" "$CALLS" | cut -d: -f1)
    [ -n "$gpu" ]
    [ "$hm" -lt "$gpu" ]
}

@test "ensure_group dry run works before the group exists" {
    printf '#!/usr/bin/env bash\nexit 2\n' > "$STUBS/getent"
    chmod +x "$STUBS/getent"
    BOOTSTRAP_DRY=1
    run bash -c 'set -euo pipefail; source "$1/bootstrap"; BOOTSTRAP_DRY=1; ensure_group docker' _ "$ROOT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY] Would run: sudo usermod -aG docker roy"* ]]
}
