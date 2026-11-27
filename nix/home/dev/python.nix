{ pkgs, ... }:

{
  # No global python3: projects use a python3xx dev shell (nix/shells) or
  # `uv python install`.
  home.packages = with pkgs; [
    uv
    ruff # linter + formatter
  ];
}
