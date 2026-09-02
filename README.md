# tmux-config

A small tmux configuration for Linux, WSL, and remote Linux servers. This is
the original mouse-enabled setup, without server-specific latency tuning.

## Behavior

- Prefix: `Ctrl-b`
- Mouse reporting: enabled
- Copy mode: Vim keys
- Theme: Catppuccin Mocha
- Clipboard: tmux clipboard integration through `tmux-yank`
- Windows and panes start at index 1
- Windows are automatically renumbered

In copy mode, `v` begins a selection and `Ctrl-v` toggles rectangle selection.

## Plugins

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `tmux-plugins/tmux-yank`
- `catppuccin/tmux`

## tmux 3.7c

The configuration itself is intentionally simple. The optional installer
builds the official tmux 3.7c release, verifies its SHA-256 checksum, and
installs it as `/usr/local/bin/tmux`:

```bash
sudo apt-get install build-essential libevent-dev libncurses-dev bison pkg-config
./install-tmux.sh
```

## Install

Install TPM once if it is not already present:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Clone this repository temporarily, run the checks, and copy the configuration
into place as a regular file:

```bash
git clone git@github.com:lucian-zh/tmux-config.git
cd tmux-config
./test.sh && ./install.sh
cd ..
rm -rf tmux-config
```

`install.sh` backs up an existing `~/.tmux.conf`, copies `tmux.conf` into
place, and reloads a running tmux server. It never creates a symbolic link.

After the first installation, start tmux and press `Ctrl-b I` if TPM has not
yet installed all configured plugins.

## Verify

```bash
tmux -V
tmux show-options -gv mouse
```

The expected values are `tmux 3.7c` and `on`.
