# The system layer of NixOS GUI hosts (tickets 07, 12, 04's Bitwarden amendment).
# Home-manager installs none of these apps; it only links their configs.
{ pkgs, ... }:

{
  # COSMIC session and greeter, plus Hyprland as the other session.
  # COSMIC's xdg portal is the mkDefault config package; checked at acceptance.
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  programs.hyprland.enable = true;

  # Audio.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  hardware.bluetooth.enable = true;
  # Mesa only: no unfree GPU driver.
  hardware.graphics.enable = true;

  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # The browser. The NixOS module, not a bare package, so policies and native
  # messaging hosts (Bitwarden's browser integration) work. Added 2026-11-27
  # at unicorn-rx0's acceptance: the installer's config had it, this repo didn't.
  programs.firefox.enable = true;

  environment.systemPackages = [
    pkgs.ghostty
    pkgs.bitwarden-desktop
    pkgs.wl-clipboard
    pkgs.google-chrome # unfree: allowed by name in default.nix
  ];
}
