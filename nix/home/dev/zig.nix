{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zig
    zls # language server (enabled in configs/nvim/lua/plugins/lsp.lua)
  ];
}
