# proto: for repos shared with teammates who don't use Nix. Their .prototools is
# authoritative: inside such a repo, `proto activate` puts the pinned tools
# (node, pnpm, moon…) ahead of the Nix ones on PATH; outside, Nix's versions win.
# proto's own settings are env vars here, not a ~/.proto/.prototools file.
{ pkgs, ... }:

{
  home.packages = [ pkgs.proto ];

  home.sessionVariables = {
    # Install a pinned tool the first time it's used instead of erroring.
    PROTO_AUTO_INSTALL = "true";
  };

  programs.zsh.initContent = ''
    eval "$(proto activate zsh)"
  '';
}
