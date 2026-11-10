# User layer: identical on every host. Each imported file owns one topic: its
# packages, config files, environment variables, PATH entries and aliases.
{ config, username, ... }:

let
  # Where this repo is cloned on every host. ./bootstrap refuses any other path.
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  imports = [
    ./shell
  ];

  _module.args = {
    inherit dotfiles;

    # `linkConfig "<app>/<path>"` links a file or folder from configs/. It's a
    # live link to the repo, not a read-only store copy: edits apply
    # immediately (no rebuild) and apps can still write to their own config.
    linkConfig = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/configs/${path}";
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Tools installed by other installers (uv tool install, pipx, ...).
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;

  # Read the home-manager release notes before changing this.
  home.stateVersion = "26.05";
}
