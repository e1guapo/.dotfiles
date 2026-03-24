#!/bin/sh
# Ensure keyd is installed, then install keyd config/service under /etc.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_FILE="$SCRIPT_DIR/../etc/keyd/default.conf"
SOURCE_SERVICE_FILE="$SCRIPT_DIR/../etc/systemd/system/keyd.service"
DEST_DIR="/etc/keyd"
DEST_FILE="$DEST_DIR/default.conf"
DEST_SERVICE_FILE="/etc/systemd/system/keyd.service"

if [ ! -f "$SOURCE_FILE" ]; then
    printf 'install_keyd_config: missing source file: %s\n' "$SOURCE_FILE" >&2
    exit 1
fi

if [ ! -f "$SOURCE_SERVICE_FILE" ]; then
    printf 'install_keyd_config: missing service file: %s\n' "$SOURCE_SERVICE_FILE" >&2
    exit 1
fi

ROOT_KEYD_BIN=$(sudo -i sh -lc 'command -v keyd' 2>/dev/null || true)
if [ -z "$ROOT_KEYD_BIN" ]; then
    if ! sudo -i sh -lc 'command -v guix >/dev/null 2>&1'; then
        printf 'install_keyd_config: root has no keyd and no guix.\n' >&2
        printf 'Install keyd manually (or install Guix) and rerun.\n' >&2
        exit 1
    fi

    printf 'install_keyd_config: keyd not found for root; installing via Guix...\n'
    sudo -i guix install keyd
    ROOT_KEYD_BIN=$(sudo -i sh -lc 'command -v keyd' 2>/dev/null || true)
    if [ -z "$ROOT_KEYD_BIN" ]; then
        printf 'install_keyd_config: keyd install finished but binary still missing in root PATH.\n' >&2
        exit 1
    fi
fi

ESC_ROOT_KEYD_BIN=$(printf '%s\n' "$ROOT_KEYD_BIN" | sed 's/[|&]/\\&/g')
TMP_SERVICE_FILE=$(mktemp)
trap 'rm -f "$TMP_SERVICE_FILE"' EXIT
sed "s|@KEYD_BIN@|$ESC_ROOT_KEYD_BIN|g" "$SOURCE_SERVICE_FILE" > "$TMP_SERVICE_FILE"

sudo install -m 644 -D "$SOURCE_FILE" "$DEST_FILE"
sudo install -m 644 -D "$TMP_SERVICE_FILE" "$DEST_SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable --now keyd
sudo systemctl restart keyd

printf 'Installed %s\n' "$DEST_FILE"
printf 'Installed %s\n' "$DEST_SERVICE_FILE"
printf 'keyd service enabled and restarted.\n'
