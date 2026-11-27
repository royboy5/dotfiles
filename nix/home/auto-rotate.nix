# Auto-rotate for tablets: turns the built-in screen to follow the
# accelerometer. Needs iio-sensor-proxy from the system layer. Hyprland starts
# it from hyprland.lua; COSMIC from this autostart entry.
{ pkgs, ... }:

let
  auto-rotate = pkgs.writeShellApplication {
    name = "auto-rotate";
    text = builtins.readFile ./scripts/auto-rotate.sh;
  };
in
{
  home.packages = [ auto-rotate ];

  xdg.configFile."autostart/auto-rotate.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Auto-rotate
    Comment=Turn the screen to follow the accelerometer
    Exec=${auto-rotate}/bin/auto-rotate
    OnlyShowIn=COSMIC;
    NoDisplay=true
  '';
}
