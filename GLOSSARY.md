# Dotfiles

Personal machine provisioning across Arch, Fedora, Bazzite and NixOS: what gets installed and how each tool is configured.

## Language

**User layer**:
Everything identical on every target machine: CLI tools, shell, editor, git, terminal multiplexers and their config files.
_Avoid_: home config, dotfiles (when meaning only this half)

**System layer**:
Everything that differs per OS: the native package manager, desktop environment, drivers, system services and GUI apps.
_Avoid_: OS config, base system

**Target OS**:
One of the operating systems this repo supports: Arch, Fedora, Bazzite or NixOS. An Arch derivative such as EndeavourOS counts as Arch.
_Avoid_: platform, distro (when meaning the supported set), EndeavourOS (as a separate target OS)

**Host**:
One real machine with its own output in the flake, named by its hostname.
_Avoid_: box, machine config, profile

