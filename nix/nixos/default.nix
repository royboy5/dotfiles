# The NixOS system layer shared by every NixOS host.
{ username, ... }:

{
  # home-manager takes home.homeDirectory from this user's home, so the user
  # must exist as a normal user (/home/roy).
  users.users.${username}.isNormalUser = true;
}
