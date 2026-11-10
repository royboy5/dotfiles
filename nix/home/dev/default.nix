# Global language toolchains. Project-specific versions belong in each
# project's own flake devShell; these are the defaults outside of one.
{ pkgs, ... }:

let
  # `project NAME`: write .envrc for a central dev shell (nix/shells) and allow it.
  project = pkgs.writeShellApplication {
    name = "project";
    runtimeInputs = with pkgs; [ direnv fzf jq ];
    text = builtins.readFile ../scripts/project.sh;
  };
in
{
  home.packages = [ project ];

  imports = [
    ./golang.nix
    ./rust.nix
    ./nodejs.nix
    ./python.nix
    ./zig.nix
    ./proto.nix
  ];

  # Auto-load a project's devShell on `cd`: put `use flake` in its .envrc
  # (or `use flake ~/.dotfiles/nix/shells/<name>`) and run `direnv allow`.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # caches the shell so it loads instantly
    config.global.hide_env_diff = true; # skip the long "export +FOO -BAR" line
  };
}
