{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    gopls
  ];

  # Nix provides the toolchain; GOPATH still holds `go install` binaries
  # and the module cache.
  home.sessionVariables.GOPATH = "$HOME/src/go";
  home.sessionPath = [ "$HOME/src/go/bin" ];
}
