---
title: Language toolchains and dev shells
type: grilling
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Which language toolchains (Go, Rust, Node, Python, Zig) are installed globally in the user layer, and which come from per-project dev shells? Should `nix/shells`, direnv and the `project` picker be ported from `~/.dotfiles`, and which shells are worth having?

From [Reconcile drifted configs](06-reconcile-configs.md): Nix (not Mason) provides nvim's language servers, so decide where gopls and rust-analyzer come from alongside their toolchains. Also decide whether starship's `DEV_SHELL` segment stays (only if dev shells are adopted). The global git ignore exists only for `.direnv/` and `.envrc`. If direnv isn't adopted, drop the global ignore and its `excludesfile` line.

From [Zsh: Nix-declared or linked files](07-zsh-shape.md): the old `env.zsh` PATH entries for proto, pnpm, cargo, opencode, flutter and the Android SDK land here. **proto/moon:** the user's moon repos use proto for version management. proto and moon are both in nixpkgs (proto 0.63.2, moon 2.6.4 at time of writing). Decide whether Nix provides proto and moon, which toolchains proto manages versus Nix (global or dev shell), PATH order between proto shims and Nix toolchains, and whether `proto activate zsh` goes in `programs.zsh.initContent`. Research question: can moon/proto use toolchains already on PATH instead of downloading, even when a repo pins versions in `.prototools`? That answer decides whether `wing-zero` needs nix-ld (see [The NixOS host's system layer](09-wing-zero-system.md)).

## Resolution

Proto/moon facts come from [Can proto/moon use toolchains already on PATH](11-proto-system-toolchains.md).

- **Dev shells: adopted from `~/.dotfiles`.** Port the central `nix/shells` flake (its own `flake.lock`, `system = "x86_64-linux"`, paths pointing at this repo) with node and python toolchain shells. (Amended during plan 1: no go or rust shells. The global go has `GOTOOLCHAIN=auto` and rustup follows `rust-toolchain.toml`, so both already pin per repo; gotools, delve and golangci-lint are global instead. A repo needing native deps gets its own `flake.nix` + `.envrc`.) `envs/` starts empty (`ma.nix` is work-only). Port direnv with nix-direnv (`hide_env_diff`) and the `project` fzf picker. Starship's `DEV_SHELL` segment stays, and so does the global git ignore (`.direnv/`, `.envrc`).
- **Global toolchains from Nix (user layer):**
  - **Go:** `go` and `gopls`, with `GOPATH=$HOME/src/go` and `$GOPATH/bin` on PATH.
  - **Rust:** `rustup` from Nix, with toolchains in `~/.rustup` and `~/.cargo/bin` on PATH. Bootstrap (or a home-manager activation step) runs `rustup default stable` and `rustup component add rust-analyzer`. The old `source ~/.cargo/env` goes.
  - **Zig:** `zig` and `zls`, with no zig dev shell.
  - **Python:** `uv` and `ruff`. There's no global `python3` and no jupyterlab. Projects use the `python3xx` dev shells (`UV_PYTHON_DOWNLOADS=never`) or `uv python install`.
  - **Node:** `node` and `pnpm`, as the default outside pinned repos.
- **Dropped:** opencode (a vendor CLI, per [Which layer owns each package](04-package-ownership.md)), Flutter, the Android SDK and Volta. No PATH stanzas remain for them. Mobile work would come back as an `envs/` shell.
- **nvim language servers:** lua_ls, ts_ls, gopls, rust-analyzer and zls all come from Nix or rustup globally. `kulala_ls` isn't in nixpkgs, so its source (kulala.nvim self-fetch, or dropping it) is decided during implementation with the user's confirmation.
- **proto/moon:** the moon repos are shared with teammates who don't use Nix, so the repo's `.prototools` is authoritative.
  - Nix installs `proto` but not `moon`, and `MOON_TOOLCHAIN_FORCE_GLOBALS` is not set.
  - `proto activate zsh` goes in `programs.zsh.initContent`. Inside a directory with `.prototools`, the pinned tools (Node, pnpm, moon) go ahead of Nix on PATH; outside, the Nix versions win.
  - A global `~/.proto/.prototools` with `auto-install = true` is linked from `configs/proto/`. Its contents are confirmed during implementation.
  - **Verify during implementation:** `activate` must change PATH only inside pinned directories. If it doesn't, fall back to running proto activation from each repo's `.envrc`.
  - Rejected: a hand-maintained dev shell mirroring `.prototools`, because it drifts.
- **nix-ld is needed on `wing-zero`:** proto downloads glibc builds (proto itself, Node, Python). Recorded on [The NixOS host's system layer](09-wing-zero-system.md).

## Amendment (2026-11-10, from [The NixOS host's system layer](09-wing-zero-system.md))

The NixOS host is now `unicorn-rx0`, so nix-ld goes there. `wing-zero` is now Arch and needs no nix-ld.
