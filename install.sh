#!/bin/sh
# Install a coherent local copy; never fetch packages or touch network services.
set -eu
umask 077
SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PREFIX=/usr
case "$#:$*" in
    0:) ;;
    *)
        if [ "$#" = 2 ] && [ "$1" = --prefix ]; then PREFIX=$2
        else echo 'Usage: sh install.sh [--prefix DIRECTORY]' >&2; exit 2; fi;;
esac
if [ "$PREFIX" = /usr ] && [ "$(id -u)" != 0 ]; then
    echo 'Run as root to install in /usr, or use --prefix for a local install.' >&2
    exit 1
fi
[ -d "$PREFIX" ] || mkdir -p "$PREFIX"
PREFIX=$(CDPATH= cd -- "$PREFIX" && pwd)
# Paths become single-quoted literals in the launcher and rollback script.
case "$PREFIX" in *"'"*|*'
'*) echo 'Installation prefix must not contain quotes or newlines.' >&2; exit 2;; esac
BIN=$PREFIX/bin/nethelp
BASE=$PREFIX/lib/nethelp-releases
(cd "$PREFIX" && mkdir -p bin lib/nethelp-releases)
[ ! -d "$BIN" ] || { echo 'Refusing to replace a directory at the command path.' >&2; exit 1; }
LOCK=$BASE/install.lock
mkdir "$LOCK" 2>/dev/null || {
    echo "Another install may be running. If an earlier install was killed, verify it has stopped before removing $LOCK." >&2
    exit 1
}
STAGE=
TEMP=
SWITCHED=0
finish() {
    result=$?
    trap - 0 HUP INT TERM
    if [ "$result" != 0 ] && [ "$SWITCHED" = 1 ]; then
        if sh "$STAGE/rollback.sh"; then echo 'Previous command restored.' >&2
        else echo "Automatic rollback failed; recovery: $STAGE/rollback.sh" >&2; fi
    fi
    [ -z "$TEMP" ] || rm -f "$TEMP"
    rmdir "$LOCK" 2>/dev/null || true
    if [ "$result" != 0 ] && [ -n "$STAGE" ]; then
        echo "Installation did not complete. Evidence/backup: $STAGE" >&2
    fi
    exit "$result"
}
trap finish 0
trap 'exit 130' HUP INT TERM

# A release archive supplies a manifest; a Git checkout is the chosen source.
if [ -f "$SOURCE/SHA256SUMS" ]; then
    (cd "$SOURCE" && sha256sum -c SHA256SUMS) >/dev/null
fi
STAGE=$(mktemp -d "$BASE/install.XXXXXX")
printf 'stage=preparing\n' > "$STAGE/INSTALL.txt"
mkdir "$STAGE/bin" "$STAGE/lib" "$STAGE/diagnostics" "$STAGE/config" "$STAGE/docs"
copy_file() {
    [ -f "$SOURCE/$1" ] && [ ! -L "$SOURCE/$1" ] || {
        echo "Missing or symlinked source file: $1" >&2; exit 1;
    }
    cp "$SOURCE/$1" "$STAGE/$1"
    cmp "$SOURCE/$1" "$STAGE/$1" >/dev/null
    chmod 644 "$STAGE/$1"
}
for file in bin/nethelp lib/common.sh README.md LICENSE config/nethelp.conf.example docs/SOURCES.md; do copy_file "$file"; done
id=1
while [ "$id" -le 33 ]; do
    number=$(printf '%02d' "$id")
    set -- "$SOURCE/diagnostics/$number-"*.sh
    [ "$#" = 1 ] || { echo "Ambiguous diagnostic $id" >&2; exit 1; }
    copy_file "diagnostics/${1##*/}"
    id=$((id + 1))
done
for file in "$STAGE/bin/nethelp" "$STAGE/lib/common.sh" "$STAGE"/diagnostics/*.sh; do sh -n "$file"; done
chmod 755 "$STAGE/bin/nethelp"
sh "$STAGE/bin/nethelp" help 7 > "$STAGE/help-check.txt"

# Exercise the actual bounded runner locally, without probes or private config.
mkdir "$STAGE/check"
sh -c '
    NH_ROOT=$1
    . "$NH_ROOT/lib/common.sh"
    nh_defaults
    NH_TMP=$NH_ROOT/check
    NH_PLAN=0
    NH_TIMEOUT=3
    NH_BROKEN=0
    NH_DEADLINE=
    NH_CHILD=
    version=$("${NETHELP_TIMEOUT_BIN:-timeout}" --version 2>&1) || exit 1
    case "$version" in *"GNU coreutils"*) ;; *) echo "GNU coreutils timeout is required" >&2; exit 1;; esac
    nh_cmd printf "NETHELP_INSTALL_OK\n"
    [ "$NH_BROKEN" = 0 ]
' sh "$STAGE" > "$STAGE/runner-check.txt" 2>&1 || {
    cat "$STAGE/runner-check.txt" >&2
    exit 1
}
grep -qx NETHELP_INSTALL_OK "$STAGE/runner-check.txt"

if [ -e "$BIN" ] || [ -L "$BIN" ]; then cp -a "$BIN" "$STAGE/previous-launcher"; fi
printf '#!/bin/sh\nexec sh '\''%s/bin/nethelp'\'' "$@"\n' "$STAGE" > "$STAGE/launcher"
{
    printf '#!/bin/sh\nset -eu\nBIN='\''%s'\''\nSTAGE='\''%s'\''\n' "$BIN" "$STAGE"
    cat <<'ROLLBACK'
# Refuse stale rollback after a later installation or manual launcher change.
cmp "$BIN" "$STAGE/launcher" >/dev/null || {
    echo 'Command has changed since this install; refusing stale rollback.' >&2
    exit 1
}
if [ -e "$STAGE/previous-launcher" ] || [ -L "$STAGE/previous-launcher" ]; then
    temp=$(mktemp "${BIN}.restore.XXXXXX")
    rm -f "$temp"
    cp -a "$STAGE/previous-launcher" "$temp"
    mv -f "$temp" "$BIN"
else
    rm -f "$BIN"
fi
printf 'stage=rolled-back\n' > "$STAGE/INSTALL.txt"
echo 'Nethelp command rolled back. Configuration and reports were not changed.'
ROLLBACK
} > "$STAGE/rollback.sh"
chmod 700 "$STAGE/rollback.sh"
TEMP=$(mktemp "$PREFIX/bin/.nethelp.XXXXXX")
cp "$STAGE/launcher" "$TEMP"
chmod 755 "$TEMP"
printf 'stage=prepared\n' > "$STAGE/INSTALL.txt"
# Only this rename changes the active tool. Legacy modules remain untouched.
SWITCHED=1
mv -f "$TEMP" "$BIN"
TEMP=
sh "$BIN" help 7 > "$STAGE/active-check.txt"
cmp "$STAGE/help-check.txt" "$STAGE/active-check.txt" >/dev/null
printf 'stage=installed\nchecks=help-and-local-runner\n' > "$STAGE/INSTALL.txt"
SWITCHED=0
printf 'installed=%s\nchecks=passed (help and local command runner)\nbackup=%s\n' "$BIN" "$STAGE"
printf "rollback=sh '%s/rollback.sh'\n" "$STAGE"
echo 'Network services, private configuration and reports: unchanged. No reboot needed.'
