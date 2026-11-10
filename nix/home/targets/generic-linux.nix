# Non-NixOS Linux (Arch, Fedora, Bazzite): standalone home-manager on top of the
# distro. Sets XDG/terminfo paths and the GPU module (hosts turn it off if CLI-only).
{
  dotfiles,
  username,
  hostName,
  ...
}:

{
  targets.genericLinux.enable = true;

  home.shellAliases = {
    # Apply the user layer. System-layer packages: re-run ./bootstrap.
    nrs = "home-manager switch --flake ${dotfiles}/nix#${username}@${hostName}";
    # Delete ALL old generations (yours, then root's) and free their space.
    # There is nothing to roll back to afterwards.
    ngc = "nix-collect-garbage -d && sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage -d";
  };
}
