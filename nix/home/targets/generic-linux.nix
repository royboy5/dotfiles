# Non-NixOS Linux (Arch, Fedora, Bazzite): standalone home-manager on top of the
# distro. Sets XDG/terminfo paths and the GPU module (hosts turn it off if CLI-only).
{ ... }:

{
  targets.genericLinux.enable = true;
}
