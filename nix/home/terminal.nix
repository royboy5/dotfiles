# Terminal multiplexers. Ghostty's config is linked only on GUI hosts.
{ pkgs, linkConfig, ... }:

{
  home.packages = with pkgs; [
    tmux
    zellij
  ];

  xdg.configFile."zellij".source = linkConfig "zellij";
  # Plugins are managed by TPM (cloned by ./bootstrap; install with prefix + I).
  home.file.".tmux.conf".source = linkConfig "tmux/tmux.conf";
}
