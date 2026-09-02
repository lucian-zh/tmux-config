# tmux-config

A self-contained tmux configuration for remote Linux servers, especially
sessions reached through high-latency SSH connections and Windows Terminal.

## Design

- Supports tmux 3.4 or newer and has no plugin runtime dependencies. tmux 3.6
  or newer is recommended for its native pane scrollbar.
- Captures wheel events in tmux so Windows Terminal scrolls tmux history rather
  than sending Up/Down keys to applications such as Codex CLI.
- Disables tmux's mouse-drag selection, which otherwise redraws through the SSH
  round trip and feels slow on high-latency links. In Windows Terminal, hold
  `Shift` while dragging for fast local selection, then press `Ctrl-Shift-C`.
- Shows tmux's own stable, one-column scrollbar on the right of every pane when
  running tmux 3.6 or newer. Windows Terminal's native scrollbar cannot expose
  a remote tmux history buffer; tmux 3.4 and 3.5 omit the pane scrollbar.
- Keeps tmux's terminal-response parser window at 500 ms. This prevents delayed
  or split OSC 10/11 color replies from leaking into the shell as text such as
  `11;rgb:...`.
- Copies from tmux copy mode to the attached terminal with native OSC 52.
- Disables focus reporting and aggressive resize to avoid unnecessary event
  traffic and redraws on remote links.
- Uses a 30-second status refresh and no periodic shell commands.
- Forwards the active pane title to the outer terminal, so Windows Terminal's
  tab shows application state such as the current Codex task, followed by the
  server and tmux pane identity.
- Uses a compact Catppuccin Mocha status line implemented with native tmux
  styles, so a theme plugin is not required.

Terminal mouse reporting cannot expose unmodified drag selection to Windows
Terminal while sending only wheel events to tmux. This configuration chooses
reliable scrollback by default and uses `Shift` as the local-selection bypass.
`Ctrl-b M` temporarily turns mouse reporting off when extensive unmodified
drag selection is more convenient; press it again to restore tmux scrolling.

Terminal emulators must allow OSC 52 for copy-mode text to reach the local
system clipboard.

## Key Behavior

- Prefix: `Ctrl-b`
- Scroll with the wheel: enter and navigate tmux scrollback.
- Select locally in Windows Terminal: `Shift` + drag.
- Copy a Windows Terminal selection: `Ctrl-Shift-C`.
- Toggle tmux mouse reporting: `Ctrl-b M`.
- Right scrollbar: tmux's 50,000-line pane history (tmux 3.6 or newer).
- Windows Terminal tab title: active application title, host, and tmux pane.
- Enter copy mode: `Ctrl-b [`
- Start a selection: `v`
- Toggle rectangle selection: `Ctrl-v`
- Copy and leave copy mode: `y`
- Windows and panes start at index 1 and windows are automatically renumbered.
- Scrollback history contains 50,000 lines.

## tmux Version

Ubuntu 24.04 currently packages tmux 3.4. The configuration works on that
version, but the native pane scrollbar requires tmux 3.6 or newer. The optional
installer builds the pinned official tmux 3.7c release, verifies its SHA-256,
and installs a regular binary at `/usr/local/bin/tmux`:

```bash
sudo apt-get install build-essential libevent-dev libncurses-dev bison pkg-config
./install-tmux.sh
```

Replacing the binary does not replace an already running tmux server. The
installer deliberately leaves existing sessions intact; they keep their old
server version until all sessions exit naturally. Compare the installed client
and running server with:

```bash
tmux -V
tmux display-message -p '#{version}'
```

The right pane scrollbar becomes active when both commands report 3.6 or newer.

## Install

The installer copies the configuration to `~/.tmux.conf` as a regular file. It
does not create a symbolic link. An existing file or link is backed up with a
timestamp, and a running tmux server is reloaded automatically.

```bash
git clone git@github.com:lucian-zh/tmux-config.git
cd tmux-config
./test.sh
./install.sh
cd ..
rm -rf tmux-config
```

HTTPS cloning also works:

```bash
git clone https://github.com/lucian-zh/tmux-config.git
```

## Update

Clone a fresh copy, run the checks, install it, and remove the clone again:

```bash
git clone git@github.com:lucian-zh/tmux-config.git
cd tmux-config
./test.sh && ./install.sh
cd ..
rm -rf tmux-config
```

## Verify

```bash
tmux -V
tmux show-options -sv escape-time
tmux show-options -gv mouse
tmux show-options -sv set-clipboard
tmux show-options -gv set-titles
tmux show-options -gwv pane-scrollbars 2>/dev/null || true
```

Expected values are `500`, `on`, `external`, `on`, and (on tmux 3.6+) `on`.
When no tmux server is running, use `./test.sh` instead.

`test.sh` uses an isolated tmux socket. On Linux systems with `script` and
`timeout`, it also simulates an OSC color reply split into delayed network
fragments and verifies that no response text reaches the shell pane.
