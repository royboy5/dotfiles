#!/usr/bin/env bash
# unicorn-rx0: Dell XPS 13 9370, NixOS. The system layer (packages, COSMIC,
# Hyprland, services) and home-manager are one nixos-rebuild. NixOS owns
# /etc/nix/nix.conf and the login shell, so none of the non-NixOS steps run.

# nixos_switch <host>: --dry only builds the system, without a ./result link
# and without sudo. Flakes aren't in a fresh NixOS's nix.conf, so every run
# passes them explicitly.
nixos_switch() {
    local host="$1" ref="$DOTFILES_ROOT/nix"
    if [[ "${BOOTSTRAP_DRY:-0}" == "1" ]]; then
        log_info "nixos-rebuild build ($host)..."
        nix "${NIX_FLAGS[@]}" build --no-link "$ref#nixosConfigurations.$host.config.system.build.toplevel"
    else
        log_info "nixos-rebuild switch ($host)..."
        sudo nixos-rebuild switch --flake "$ref#$host" --option experimental-features "nix-command flakes"
    fi
}

host_unicorn_rx0() {
    local hw="$DOTFILES_ROOT/nix/nixos/hardware/unicorn-rx0.nix"
    if [[ ! -f "$hw" ]]; then
        log_error "$hw is missing. Generate it on this machine:"
        echo "        nixos-generate-config --show-hardware-config > $hw" >&2
        echo "        git -C \"$DOTFILES_ROOT\" add nix/ && git -C \"$DOTFILES_ROOT\" commit" >&2
        return 1
    fi
    lock_flake
    nixos_switch unicorn-rx0
    ensure_tpm
    ensure_rustup
}
