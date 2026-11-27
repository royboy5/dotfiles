{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    gopls
    gotools # goimports and friends
    delve
    golangci-lint
  ];

  # No Go dev shell: the nixpkgs go has GOTOOLCHAIN=auto, so a repo whose
  # go.mod asks for a newer version gets that toolchain downloaded.

  # Nix provides the toolchain; GOPATH still holds `go install` binaries
  # and the module cache.
  home.sessionVariables.GOPATH = "$HOME/src/go";
  home.sessionPath = [ "$HOME/src/go/bin" ];
}
