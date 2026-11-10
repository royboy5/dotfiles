# wsl: Fedora under WSL. CLI only, so no GPU module and no GUI configs.
{ ... }:

{
  imports = [ ../home/targets/generic-linux.nix ];

  targets.genericLinux.gpu.enable = false;
}
