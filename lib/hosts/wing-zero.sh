#!/usr/bin/env bash
# wing-zero: Surface Pro 3, EndeavourOS (the Arch path). GUI host: COSMIC and
# Hyprland side by side; the session is picked at login, which this repo
# doesn't configure.

# Everything here is in pacman's [extra]; no AUR. `cosmic` is a package group.
PACMAN_PACKAGES_WING_ZERO=(
    zsh ghostty bitwarden docker reflector wl-clipboard
    cosmic hyprland thermald
    ttf-firacode-nerd ttf-jetbrains-mono-nerd
)

host_wing_zero() {
    # -u is required: -Sy without it is a partial upgrade. --noconfirm takes
    # every member of the cosmic group.
    log_info "Installing system packages: ${PACMAN_PACKAGES_WING_ZERO[*]}"
    execute sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES_WING_ZERO[@]}"
    ensure_service docker.service reflector.timer thermald.service
    ensure_group docker
    ensure_login_shell /usr/bin/zsh
    # The Surface Pro 3 freezes when a Wayland desktop (COSMIC or Hyprland)
    # starts, unless the i915 driver's Panel Self Refresh is off.
    ensure_kernel_param i915.enable_psr=0
    ensure_nix
    ensure_flakes
    lock_flake
    hm_switch wing-zero
    ensure_gpu_setup
    ensure_tpm
    ensure_rustup
}
