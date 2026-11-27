#!/usr/bin/env bash
# wsl: Fedora under WSL. CLI only: no GUI apps, no GPU setup, no containers.

: "${SYSTEMD_DIR:=/run/systemd/system}"

# zsh (the login shell) plus what the Nix installer needs that the image lacks.
DNF_PACKAGES_WSL=(zsh)

host_wsl() {
    # The Nix daemon is a systemd service.
    if [[ ! -d "$SYSTEMD_DIR" ]]; then
        log_error "systemd isn't running. Add this to /etc/wsl.conf:"
        printf '            [boot]\n            systemd=true\n' >&2
        echo "        then run \`wsl --shutdown\` from Windows, reopen WSL and re-run ./bootstrap." >&2
        return 1
    fi

    log_info "Installing system packages: ${DNF_PACKAGES_WSL[*]}"
    execute sudo dnf install -y "${DNF_PACKAGES_WSL[@]}"
    ensure_login_shell /usr/bin/zsh
    ensure_nix
    ensure_flakes
    lock_flake
    hm_switch wsl
    ensure_tpm
    ensure_rustup
}
