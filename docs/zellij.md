[Home](/README.md) > Zellij

# Zellij

Terminal multiplexer, and the one that starts with every terminal. Installed by
Nix (`nix/home/terminal.nix`); the config in `configs/zellij/` is linked to
`~/.config/zellij`.

| Path | Purpose |
|---|---|
| `config.kdl` | Theme, behaviour, and the few keybinds that differ from the defaults |
| `layouts/dev.kdl` | Editor + shell + git layout |

Anything not set in `config.kdl` is a zellij default. See them all with
`zellij setup --dump-config`.

## Starting

A new interactive zsh starts zellij automatically, except over SSH and inside
zellij itself. To get a plain shell for once: `ZELLIJ_AUTOSTART=0 zsh`. To turn
it off on a machine, put `export ZELLIJ_AUTOSTART=0` in
`~/.config/zsh/local_env.zsh` (see [Zsh](zsh.md)).

## Modes

Zellij is modal rather than prefix-based (unlike [tmux](tmux.md)). The status
bar shows the keys for the current mode.

| Key | Mode |
|---|---|
| `Ctrl p` | Pane |
| `Ctrl t` | Tab |
| `Ctrl n` | Resize |
| `Ctrl s` | Scroll / search |
| `Ctrl o` | Session |
| `Ctrl g` | Lock (passes every key through to the app) |
| `Esc` | Back to normal |

Move mode has no key, because Ctrl-h now moves focus (below).

`Ctrl q` is unbound because it kills the whole session. Quit deliberately with
`Ctrl o` then `q`; detach with `Ctrl o` then `d`.

## Moving around

**Ctrl-h/j/k/l** moves between zellij panes and nvim splits as if they were one
grid: inside nvim it moves between splits, and at nvim's edge it carries on
into the next zellij pane. Focus stops at the outer edge rather than wrapping or
switching tab. This uses [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator)
on the zellij side and [smart-splits.nvim](nvim.md) on the nvim side. Since
Ctrl-l moves focus, it no longer clears a shell pane: type `clear` instead.

| Keys | Action |
|---|---|
| `Ctrl-Shift-h` / `Ctrl-Shift-l` | Previous / next tab |
| `Alt-h` / `Alt-l` | Focus left / right pane, or the previous / next tab at the edge |
| `Alt-i` / `Alt-o` | Move the current tab left / right |
| `Ctrl-t` then `1`–`9` | Go to tab N |
| `Ctrl-t` then `n` / `x` / `r` | New / close / rename tab |
| `Ctrl-t` then `d`, or `Alt-d` | New tab with the dev layout |

**Windows Terminal:** `Ctrl-Shift-h/l` only work if the terminal sends them
differently from plain Ctrl-h/l. If they move between panes instead of
switching tab, use `Alt-h/l` or `Ctrl-t` then `h/l`.

## Common commands

```bash
zellij                          # new session
zellij --layout dev             # new session with the dev layout
zellij list-sessions
zellij attach <name>
zellij attach --create <name>   # attach, or create it if missing
```

## Notes

- The config is read when a session starts. Changes apply to **new** sessions.
- `session_serialization` is on, so sessions survive a reboot: `zellij attach <name>`.
- Selecting text copies it to the system clipboard through the terminal
  (OSC 52), on every host including WSL.
- Lock mode (`Ctrl g`) is the escape hatch when a zellij key collides with an app.
