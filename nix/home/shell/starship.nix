# Prompt. Installs starship, hooks it into zsh and links its config.
{ linkConfig, ... }:

{
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = linkConfig "starship/starship.toml";
}
