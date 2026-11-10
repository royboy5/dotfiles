{ pkgs, ... }:

{
  # rustup from Nix; toolchains still live in ~/.rustup and are managed with
  # `rustup` as usual (rust-toolchain.toml, `rustup component add`, ...).
  home.packages = [ pkgs.rustup ];

  # Binaries from `cargo install`.
  home.sessionPath = [ "$HOME/.cargo/bin" ];
}
