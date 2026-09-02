#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
socket_name=tmux-config-test-$$

cleanup() {
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM

tmux -L "$socket_name" -f "$script_dir/tmux.conf" \
    new-session -d -s config-test
tmux -L "$socket_name" source-file "$script_dir/tmux.conf"
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

assert_server_option set-clipboard on
assert_server_option escape-time 500
assert_server_option 'terminal-features[100]' 'xterm-256color:RGB'
assert_server_option 'terminal-features[101]' 'tmux-256color:RGB'
assert_session_option default-terminal tmux-256color
assert_session_option mouse on
assert_session_option base-index 1
assert_session_option renumber-windows on
assert_session_option set-titles on
assert_session_option set-titles-string '#T'
assert_session_option @nova-segment-session-colors '#{?client_prefix,#ffb86c,#50fa7b} #282a36'
assert_window_option pane-base-index 1
assert_window_option mode-keys vi
assert_window_option pane-scrollbars off

selection_binding=$(key_binding copy-mode-vi v)
case "$selection_binding" in
    *begin-selection*) ;;
    *)
        printf 'Missing vi-mode v selection binding.\n' >&2
        exit 1
        ;;
esac

rectangle_binding=$(key_binding copy-mode-vi C-v)
case "$rectangle_binding" in
    *rectangle-toggle*) ;;
    *)
        printf 'Missing vi-mode Ctrl-v rectangle binding.\n' >&2
        exit 1
        ;;
esac

printf 'tmux configuration checks passed.\n'
