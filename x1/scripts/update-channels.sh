#!/bin/sh
set -eu

CHANNELS_BASE="files/.config/guix/base-channels.scm"
CHANNELS_DEST="files/.config/guix/channels.scm"
HOME_CONFIG_FILE="config/home/home-configuration.scm"

echo "Pulling Guix with ${CHANNELS_BASE}..."
guix pull \
    --channels="${CHANNELS_BASE}" \
    --allow-downgrades

echo "Reconfiguring Guix Home using ${HOME_CONFIG_FILE}..."
if guix home reconfigure "${HOME_CONFIG_FILE}"; then
    echo "Recording channel state in ${CHANNELS_DEST}..."
    guix describe --format=channels > "${CHANNELS_DEST}"
    echo "Channels updated!"
else
    echo "guix home reconfigure failed. Rolling back and leaving channels intact." >&2
    guix pull --roll-back
    exit 1
fi
