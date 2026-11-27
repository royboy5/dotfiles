[Home](/README.md) > Tmux

# Tmux

Kept alongside [zellij](zellij.md), which is the default. Installed by Nix
(`nix/home/terminal.nix`); `configs/tmux/tmux.conf` is linked to `~/.tmux.conf`.

## Plugins

Plugins come from [TPM](https://github.com/tmux-plugins/tpm), which
`./bootstrap` clones to `~/.tmux/plugins/tpm`. Install them once per machine:
start tmux and press `prefix + I` (capital i). `prefix + U` updates them.

## Keys

Prefix is **Ctrl-Space**.

| Keys | Action |
|---|---|
| `prefix` `\|` / `-` | Split side by side / stacked |
| `prefix` `h/j/k/l` | Move between panes |
| `Alt-h/j/k/l` | Move between panes, no prefix |
| `Ctrl-h/j/k/l` | Move between panes and nvim splits ([vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)) |
| `prefix` `H/J/K/L` | Resize pane |
| `prefix` `<` / `>` | Swap pane |
| `prefix` `Ctrl-l` | Clear the screen and scrollback |
| `prefix` `r` | Reload the config |

Ctrl-hjkl moves from a tmux pane into nvim and between nvim's splits, but not
back out of nvim into tmux: nvim's side (smart-splits) is set up for zellij.
Use `Alt-h/j/k/l` to leave nvim.
