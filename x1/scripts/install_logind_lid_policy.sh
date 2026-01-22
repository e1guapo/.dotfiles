#!/bin/sh
# Install logind lid-switch policy drop-in under /etc.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_FILE="$SCRIPT_DIR/../files/etc/systemd/logind.conf.d/50-lid-switch.conf"
DEST_DIR="/etc/systemd/logind.conf.d"
DEST_FILE="$DEST_DIR/50-lid-switch.conf"

if [ ! -f "$SOURCE_FILE" ]; then
    printf 'install_logind_lid_policy: missing source file: %s\n' "$SOURCE_FILE" >&2
    exit 1
fi

sudo install -m 644 -D "$SOURCE_FILE" "$DEST_FILE"

printf 'Installed %s\n' "$DEST_FILE"
printf 'Run: sudo systemctl restart systemd-logind (or reboot)\n'
