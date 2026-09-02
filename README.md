# tmux-config

My tmux configuration for Linux and WSL.

## Environment

- tmux 3.4
- Prefix: `Ctrl-b`
- Theme: Catppuccin Mocha
- Clipboard: `wl-copy` on the current machine

## Plugins

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `tmux-plugins/tmux-yank`
- `catppuccin/tmux`

## Highlights

- Windows and panes start at index 1.
- Windows are automatically renumbered.
- Mouse support and Vim-style copy mode are enabled.
- `v` begins a selection, `Ctrl-v` toggles rectangle selection, and `y`
  copies to the system clipboard.
- The status line shows the session, window names, current directory, active
  program, and time.

## Setup

```bash
git clone git@github.com:lucian-zh/tmux-config.git ~/projects/tmux-config
ln -s ~/projects/tmux-config/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start tmux and press `Ctrl-b I` to install the configured plugins. If
`~/.tmux.conf` already exists, move or remove it before creating the link.

## Update

```bash
cd ~/projects/tmux-config
git pull --ff-only
tmux source-file ~/.tmux.conf
```
