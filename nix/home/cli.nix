# Everyday command-line tools.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell & core utils
    bashInteractive
    curl
    wget
    tree
    htop

    # Search, view, navigate
    bat
    eza
    fd
    fzf
    ripgrep
    jq
    jless
    yq-go

    # Misc
    httpie
    k9s
  ];

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "rg --files";
    FZF_DEFAULT_OPTS = "-m --height 50% --border";
  };

  # Modern replacements for core commands. grep and find stay the real tools
  # (commands pasted from elsewhere use their flags); use rg and fd by name.
  home.shellAliases = {
    ls = "eza --icons --group-directories-first";
    ll = "eza -la --icons --git --group-directories-first";
    lt = "eza --tree --level=2 --icons";
    cat = "bat --style=plain"; # plain, for copying
    catp = "bat"; # paged, with line numbers
  };
}
