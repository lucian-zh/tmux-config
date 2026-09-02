#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
socket_name=tmux-config-test-$$

cleanup() {
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

tmux -L "$socket_name" -f "$script_dir/tmux.conf" new-session -d -s config-test
# A reload must clean up values appended by an older configuration.
tmux -L "$socket_name" set-option -as terminal-features \
    ',xterm-256color:RGB'
tmux -L "$socket_name" source-file "$script_dir/tmux.conf"

assert_server_option() {
    option=$1
    expected=$2
    actual=$(tmux -L "$socket_name" show-options -sv "$option")
    [ "$actual" = "$expected" ] || {
        printf 'Expected %s=%s, got %s\n' "$option" "$expected" "$actual" >&2
        exit 1
    }
}

assert_session_option() {
    option=$1
    expected=$2
    actual=$(tmux -L "$socket_name" show-options -gv "$option")
    [ "$actual" = "$expected" ] || {
        printf 'Expected %s=%s, got %s\n' "$option" "$expected" "$actual" >&2
        exit 1
    }
}

assert_window_option() {
    option=$1
    expected=$2
    actual=$(tmux -L "$socket_name" show-window-options -gv "$option")
    [ "$actual" = "$expected" ] || {
        printf 'Expected %s=%s, got %s\n' "$option" "$expected" "$actual" >&2
        exit 1
    }
}

key_binding() {
    table=$1
    key=$2
    tmux -L "$socket_name" list-keys -T "$table" | \
        awk -v key="$key" '$4 == key { print; exit }'
}

assert_server_option escape-time 500
assert_server_option set-clipboard external
assert_server_option copy-command 'tmux load-buffer -w -'
assert_session_option mouse on
assert_session_option focus-events off
assert_session_option base-index 1
assert_session_option renumber-windows on
assert_session_option status-interval 30
assert_session_option set-titles on
assert_session_option set-titles-string \
    '#{pane_title} | #{host_short} | #S:#I.#P'
assert_window_option pane-base-index 1
assert_window_option mode-keys vi
assert_window_option aggressive-resize off

tmux_version=$(tmux -L "$socket_name" display-message -p '#{version}')
case "$tmux_version" in
    3.[6-9]* | 3.[1-9][0-9]* | [4-9].* | [1-9][0-9]*.*)
        assert_window_option pane-scrollbars on
        assert_window_option pane-scrollbars-position right
        assert_window_option pane-scrollbars-style \
            'fg=#89b4fa,bg=#313244,width=1,pad=0'
        ;;
esac

copy_binding=$(key_binding copy-mode-vi y)
printf '%s\n' "$copy_binding" | grep -q 'copy-pipe-and-cancel' || {
    printf 'Missing vi-mode y copy binding.\n' >&2
    exit 1
}

wheel_binding=$(key_binding root WheelUpPane)
printf '%s\n' "$wheel_binding" | grep -q 'copy-mode -e' || {
    printf 'WheelUpPane does not enter tmux copy mode.\n' >&2
    exit 1
}

for table in root copy-mode copy-mode-vi; do
    if [ -n "$(key_binding "$table" MouseDrag1Pane)" ]; then
        printf 'MouseDrag1Pane is still bound in %s.\n' "$table" >&2
        exit 1
    fi
    if [ -n "$(key_binding "$table" MouseDragEnd1Pane)" ]; then
        printf 'MouseDragEnd1Pane is still bound in %s.\n' "$table" >&2
        exit 1
    fi
done

mouse_toggle=$(key_binding prefix M)
printf '%s\n' "$mouse_toggle" | grep -q 'set-option -g mouse off' || {
    printf 'Missing prefix + M mouse toggle.\n' >&2
    exit 1
}

feature_count=$(tmux -L "$socket_name" show-options -sv terminal-features | \
    grep -c '^xterm-256color:RGB:clipboard$')
[ "$feature_count" -eq 1 ] || {
    printf 'terminal-features is not reload-safe.\n' >&2
    exit 1
}

stale_feature_count=$(tmux -L "$socket_name" show-options -sv \
    terminal-features | grep -c '^xterm-256color:RGB$' || true)
[ "$stale_feature_count" -eq 0 ] || {
    printf 'Stale terminal-features entries survived reload.\n' >&2
    exit 1
}

# Simulate an OSC color reply split into 50 ms network fragments. tmux 3.4
# must consume the whole reply instead of passing its tail to the pane.
if command -v script >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    {
        sleep 0.3
        printf '\033]10;rgb:dede/dede/dede'
        sleep 0.05
        printf '\033\\'
        sleep 0.05
        printf '\033]11;rgb:0c0c/'
        sleep 0.05
        printf '0c0c/'
        sleep 0.05
        printf '0c0c'
        sleep 0.05
        printf '\033\\'
        sleep 0.2
        printf '\r'
        sleep 0.2
        # SGR mouse wheel-up at pane coordinates 2,2.
        printf '\033[<64;2;2M'
        sleep 0.2
        printf '\002d'
    } | TERM=xterm-256color timeout 5 script -qefc \
        "tmux -L $socket_name attach-session -t config-test" /dev/null \
        >/dev/null

    pane_output=$(tmux -L "$socket_name" capture-pane -p -S -100 \
        -t config-test:1.1)
    if printf '%s\n' "$pane_output" | grep -Eq 'rgb:|execute:'; then
        printf 'A split OSC response leaked into the pane.\n' >&2
        exit 1
    fi

    pane_in_mode=$(tmux -L "$socket_name" display-message -p \
        -t config-test:1.1 '#{pane_in_mode}')
    [ "$pane_in_mode" -eq 1 ] || {
        printf 'A wheel-up event did not enter tmux copy mode.\n' >&2
        exit 1
    }
else
    printf 'Skipped PTY behavior tests: script or timeout is unavailable.\n'
fi

printf 'tmux configuration checks passed.\n'
