#!/usr/bin/env sh
set -eu

tmux_version=3.7c
archive_sha256=7c60cae9a0e25288e2e24750aafc9e8800fc7fd4555e447e1b29ee4201cfb3bf
install_prefix=${PREFIX:-/usr/local}
archive_url=https://github.com/tmux/tmux/releases/download/${tmux_version}/tmux-${tmux_version}.tar.gz

for required_command in cc make pkg-config yacc curl sha256sum tar; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'Missing build command: %s\n' "$required_command" >&2
        printf '%s\n' \
            'On Ubuntu, install: build-essential libevent-dev libncurses-dev bison pkg-config' >&2
        exit 1
    fi
done

build_parent=${TMPDIR:-/tmp}
build_directory=$(mktemp -d "${build_parent%/}/tmux-build.XXXXXX")
case "$build_directory" in
    "${build_parent%/}"/tmux-build.*) ;;
    *)
        printf 'Unexpected temporary directory: %s\n' "$build_directory" >&2
        exit 1
        ;;
esac

cleanup() {
    rm -rf -- "$build_directory"
}
trap cleanup EXIT HUP INT TERM

archive_file=$build_directory/tmux-${tmux_version}.tar.gz
curl -fL --retry 3 --connect-timeout 15 -o "$archive_file" "$archive_url"
printf '%s  %s\n' "$archive_sha256" "$archive_file" | sha256sum -c -
tar -xzf "$archive_file" -C "$build_directory"

jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1\n')
case "$jobs" in
    '' | *[!0-9]*) jobs=1 ;;
esac

cd "$build_directory/tmux-${tmux_version}"
./configure --prefix="$install_prefix" --sysconfdir=/etc
make -j "$jobs"

if [ "$(id -u)" -eq 0 ]; then
    make install
else
    command -v sudo >/dev/null 2>&1 || {
        printf 'sudo is required to install under %s.\n' "$install_prefix" >&2
        exit 1
    }
    sudo make install
fi

installed_binary=$install_prefix/bin/tmux
installed_version=$("$installed_binary" -V)
[ "$installed_version" = "tmux $tmux_version" ] || {
    printf 'Expected tmux %s, got %s.\n' "$tmux_version" "$installed_version" >&2
    exit 1
}
printf 'Installed %s as %s.\n' "$installed_version" "$installed_binary"

if "$installed_binary" list-sessions >/dev/null 2>&1; then
    server_version=$($installed_binary display-message -p '#{version}')
    if [ "$server_version" != "$tmux_version" ]; then
        printf 'Running tmux server remains on %s; it was not restarted.\n' \
            "$server_version"
        printf 'The new version takes effect after that server exits naturally.\n'
    fi
fi
