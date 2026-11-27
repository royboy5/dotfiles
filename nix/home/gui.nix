# GUI-only config links, imported by GUI host files only (not wsl). The apps
# themselves (Ghostty, Hyprland, COSMIC) come from the host's system layer.
{ linkConfig, ... }:

{
  xdg.configFile."ghostty".source = linkConfig "ghostty";
  xdg.configFile."hypr".source = linkConfig "hypr";
}
