[Home](/README.md) > Dev shells

# Dev shells

Most tools are global (the **user layer**). A dev shell is for the cases where
a project needs a different version: it's a Nix shell from the central flake in
`nix/shells/`, loaded by [direnv](https://direnv.net) when you `cd` into the
project and unloaded when you leave.

## Using one

```bash
cd ~/src/my-app
project            # pick a shell with fzf
project node22     # or name it
project list       # list the shells
project off        # remove the .envrc that project wrote
```

`project` writes a two-line `.envrc` (`use flake ~/.dotfiles/nix/shells#<name>`)
and runs `direnv allow`. The prompt then shows the shell as `[❄ node22]`.
`.envrc` and `.direnv/` are in the global git ignore, so they never get
committed to the project.

The first load builds the shell, which takes a moment; after that
[nix-direnv](https://github.com/nix-community/nix-direnv) caches it.

## Available shells

| Shell | Contents |
|---|---|
| `node` | latest Node, latest pnpm |
| `node22`, `node24` | that Node major, pnpm 10 |
| `python312`, `python313` | that Python and uv; creates and activates `.venv` |

There are no Go or Rust shells: the global `go` downloads whatever version a
repo's `go.mod` asks for, and the global `rustup` installs whatever its
`rust-toolchain.toml` pins.

## Adding a shell

- **A new version of a toolchain:** add a line to `toolchains` in
  `nix/shells/flake.nix`, e.g. `node20 = mkNode { node = pkgs.nodejs_20; };`.
- **A project or combo shell:** create `nix/shells/envs/<name>.nix`. It's a
  function returning a shell, and becomes the shell `<name>`:
  ```nix
  { pkgs, shells, ... }:
  pkgs.mkShell {
    inputsFrom = [ shells.node22 ];
    packages = [ pkgs.postgresql ];
  }
  ```
  `git add` it before use; flakes ignore untracked files.

Projects that already use the shell pick up edits on their next `cd`.

## Updating

The shells have their own lock (`nix/shells/flake.lock`), separate from the
rest of the config, so project toolchains only change when you ask:

```bash
nus   # update the dev shells' lock
```

## proto

[proto](https://moonrepo.dev/proto) is for repos that pin tool versions in a
`.prototools` file instead of a dev shell. `proto activate` in zsh puts the
pinned versions first on `PATH` while you're inside such a repo and removes
them when you leave, so outside it you get the global (Nix) versions.
`PROTO_AUTO_INSTALL=true` installs a pinned version the first time it's needed.

If a repo pins versions with proto, don't also give it a dev shell for the same
tool; one of them would shadow the other.

On `unicorn-rx0` (NixOS), proto's downloaded binaries need `nix-ld` to run; that
host's system layer enables it.
