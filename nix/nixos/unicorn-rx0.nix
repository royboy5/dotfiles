# unicorn-rx0: Dell XPS 13 9370, NixOS (ticket 09).
{ lib, nixos-hardware, ... }:

let
  hardwareFile = ./hardware/unicorn-rx0.nix;
in
{
  imports = [
    ./desktop.nix
    nixos-hardware.nixosModules.dell-xps-13-9370
  ]
  # Generated on the machine itself; absent until it is installed.
  ++ lib.optional (builtins.pathExists hardwareFile) hardwareFile;

  assertions = [
    {
      assertion = builtins.pathExists hardwareFile;
      message = "nix/nixos/hardware/unicorn-rx0.nix is missing. On unicorn-rx0, run: mkdir -p ~/.dotfiles/nix/nixos/hardware && nixos-generate-config --show-hardware-config > ~/.dotfiles/nix/nixos/hardware/unicorn-rx0.nix, then git add it (README: unicorn-rx0).";
    }
  ];

  networking.hostName = "unicorn-rx0";
  # A laptop: the timezone follows its location (geoclue, which COSMIC already
  # turns on). This leaves time.timeZone null, so don't set one here; it would
  # conflict, and the Settings app's timezone picker would be overridden.
  services.automatic-timezoned.enable = true;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # power-profiles-daemon, not system76-power (which COSMIC would otherwise
  # enable) and not TLP.
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  # Placeholder until the machine exists: replace with the installer ISO's
  # release (README: unicorn-rx0). Never change it afterwards.
  system.stateVersion = "26.05";
}
