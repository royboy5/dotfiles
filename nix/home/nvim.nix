# Neovim. The Lua config (configs/nvim) and lazy.nvim stay as-is; Nix provides
# everything around them: the editor, the language servers and formatters
# (instead of Mason) and the tools plugins shell out to.
{ pkgs, linkConfig, ... }:

{
  # lazy.nvim writes lazy-lock.json here, which is why this is a live link.
  xdg.configFile."nvim".source = linkConfig "nvim";

  home.packages = with pkgs; [
    neovim
    tree-sitter # nvim-treesitter (main) compiles parsers with it

    # Language servers. Enabled in configs/nvim/lua/plugins/lsp.lua;
    # add the package here and the server name there.
    lua-language-server # lua_ls
    typescript-language-server # ts_ls
    vscode-langservers-extracted # eslint
    # gopls and zls come from dev/; rust_analyzer from rustup (dev/rust.nix).
    # kulala.nvim runs its own built-in LSP; biome runs per project via pnpm exec.

    # Formatters (conform.nvim)
    stylua
    prettier
    black
    isort
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
    v = "nvim";
  };
}
