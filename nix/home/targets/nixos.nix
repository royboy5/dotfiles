# NixOS: home-manager runs as a module of the system, so there is no
# targets.genericLinux and no ~/.config/home-manager link.
{ dotfiles, hostName, ... }:

{
  home.shellAliases = {
    # Apply the whole system (and, with it, the user layer).
    nrs = "sudo nixos-rebuild switch --flake ${dotfiles}/nix#${hostName}";
    # Delete ALL old generations (root's, then yours) and free their space.
    # There is nothing to roll back to afterwards.
    ngc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
  };
}
