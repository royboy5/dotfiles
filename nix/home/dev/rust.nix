{ pkgs, ... }:

{
  # rustup from Nix; toolchains still live in ~/.rustup and are managed with
  # `rustup` as usual (rust-toolchain.toml, `rustup component add`, ...).
  # No Rust dev shell: rustup installs whatever a repo's rust-toolchain.toml
  # pins.
  home.packages = [ pkgs.rustup ];

  # Binaries from `cargo install`.
  home.sessionPath = [ "$HOME/.cargo/bin" ];
}
