# unicorn-rx0: Dell XPS 13, NixOS. GUI host; ghostty and Hyprland come from
# the system layer (nix/nixos).
{ ... }:

{
  imports = [
    ../home/targets/nixos.nix
    ../home/gui.nix
  ];
}
