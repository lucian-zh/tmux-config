#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file=$script_dir/tmux.conf
target_file=${HOME}/.tmux.conf

if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    timestamp=$(date '+%Y%m%d-%H%M%S')
    backup_file=${target_file}.backup-${timestamp}
    suffix=0
    while [ -e "$backup_file" ] || [ -L "$backup_file" ]; do
        suffix=$((suffix + 1))
        backup_file=${target_file}.backup-${timestamp}-${suffix}
    done
    if [ -e "$target_file" ]; then
        cp -L -- "$target_file" "$backup_file"
    else
        cp -P -- "$target_file" "$backup_file"
    fi
    printf 'Backed up %s to %s\n' "$target_file" "$backup_file"
fi

temporary_file=$(mktemp "${target_file}.tmp.XXXXXX")
trap 'rm -f -- "$temporary_file"' EXIT HUP INT TERM
cp -- "$source_file" "$temporary_file"
chmod 0644 "$temporary_file"
mv -f -- "$temporary_file" "$target_file"
trap - EXIT HUP INT TERM

printf 'Installed %s as a regular file.\n' "$target_file"
if tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$target_file"
    printf 'Reloaded the running tmux server.\n'
fi
