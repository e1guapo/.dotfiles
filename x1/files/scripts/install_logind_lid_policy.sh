#!/bin/sh
# Install logind lid-switch policy drop-in to /etc/systemd/logind.conf.d/.
# Prevents lid close from triggering hibernate (which fails due to kernel
# lockdown and falls back to poweroff).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_FILE="$SCRIPT_DIR/../etc/systemd/logind.conf.d/50-lid-switch.conf"
DEST_DIR="/etc/systemd/logind.conf.d"
DEST_FILE="$DEST_DIR/50-lid-switch.conf"

if [ ! -f "$SOURCE_FILE" ]; then
    printf 'install_logind_lid_policy: missing source file: %s\n' "$SOURCE_FILE" >&2
    exit 1
fi

sudo install -m 755 -d "$DEST_DIR"
sudo install -m 644 "$SOURCE_FILE" "$DEST_FILE"

printf 'Installed %s\n' "$DEST_FILE"
printf 'Restarting systemd-logind...\n'
sudo systemctl restart systemd-logind

printf 'Done. Verify with: busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch\n'
