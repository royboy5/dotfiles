{ pkgs, ... }:

{
  # Global default (current LTS) outside pinned repos. Pin other versions per
  # project in a dev shell, or with .prototools in repos shared with non-Nix users.
  home.packages = with pkgs; [
    nodejs
    pnpm
  ];
}
