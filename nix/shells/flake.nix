# Central dev shells for projects. Use one from a project's .envrc:
#
#   use flake ~/.dotfiles/nix/shells#node22
#
# then `direnv allow` (or just run `project node22`, which writes .envrc for you).
# nix-direnv only watches this flake.nix and flake.lock; the `watch_file` line
# that `project` adds to .envrc also covers envs/*.nix, so the shell rebuilds
# after you edit any of them. List the shells with: project list
#
# Two kinds of shell:
#   - Toolchains (node, go, rust, python…): defined inline below, rarely change.
#   - Project and combo shells: one file each in ./envs, discovered
#     automatically. envs/foo.nix becomes the shell `foo`. New files must be
#     `git add`ed before the flake can see them.
#
# This flake has its own flake.lock (separate from the system config in ../),
# so project toolchains only change when you run `nix flake update` here.
# "Latest" below means the newest version in that lock.
{
  description = "Dev shells for projects";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      # Node: creates a shell with node and an optional pnpm (defaults to pnpm 10).
      mkNode =
        {
          node ? pkgs.nodejs_latest,
          pnpm ? pkgs.pnpm_10,
        }:
        pkgs.mkShell {
          packages = [ node ] ++ lib.optional (pnpm != null) pnpm;
        };

      # Python: pairs the interpreter with uv and auto-activates a project .venv.
      mkPython =
        python:
        pkgs.mkShell {
          packages = [
            python
            pkgs.uv
          ];
          env = {
            UV_PYTHON = "${python}/bin/python3";
            UV_PYTHON_DOWNLOADS = "never";
          };
          shellHook = ''
            [ -d .venv ] || uv venv --quiet
            source .venv/bin/activate
          '';
        };

      # --- Toolchains -------------------------------------------------------
      toolchains = {
        # Latest Node + latest pnpm.
        node = mkNode {
          node = pkgs.nodejs_latest;
          pnpm = pkgs.pnpm;
        };
        node22 = mkNode { node = pkgs.nodejs_22; };
        node24 = mkNode { node = pkgs.nodejs_24; };

        python312 = mkPython pkgs.python312;
        python313 = mkPython pkgs.python313;

        # Latest Go + language server, tools (goimports…), debugger, linter.
        go = pkgs.mkShell {
          packages = with pkgs; [
            go
            gopls
            gotools
            delve
            golangci-lint
          ];
        };

        # Latest stable Rust from nixpkgs (not rustup): fixed by this flake's
        # lock, so it overrides your global rustup toolchain inside the project.
        rust = pkgs.mkShell {
          packages = with pkgs; [
            rustc
            cargo
            clippy
            rustfmt
            rust-analyzer
          ];
          # Standard library source, for rust-analyzer's go-to-definition.
          env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };
      };

      # --- Project and combo shells: one file each in ./envs ----------------
      # Each file is a function taking these arguments (use `...` to ignore the
      # rest) and returning a shell. `shells` is the toolchains above, for
      # building on with `inputsFrom`; env files can't reference each other.
      envArgs = {
        inherit pkgs lib mkNode mkPython;
        shells = toolchains;
      };
      envFiles = lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".nix" file) (
        builtins.readDir ./envs
      );
      envs = lib.mapAttrs' (
        file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (import ./envs/${file} envArgs)
      ) envFiles;

      # An env file named after a toolchain would silently replace it.
      clashes = lib.attrNames (lib.intersectAttrs toolchains envs);
    in
    assert lib.assertMsg (clashes == [ ]) "nix/shells/envs redefines toolchain shell(s): ${toString clashes}";
    {
      # Each shell exports its own name as DEV_SHELL (shown in the starship
      # prompt, configs/starship/starship.toml).
      devShells.${system} = lib.mapAttrs (name: shell: shell.overrideAttrs { DEV_SHELL = name; }) (
        toolchains // envs
      );
    };
}
