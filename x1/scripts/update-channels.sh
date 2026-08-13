#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CHANNELS_BASE="files/.config/guix/base-channels.scm"
CHANNELS_DEST="files/.config/guix/channels.scm"
HOME_CONFIG_FILE="config/home/home-configuration.scm"

# Refresh the guix-daemon SELinux policy if root's guix shipped a newer one.
# A stale module makes builds fail with AVC denials under enforcing.  This is a
# no-op -- and prompts for nothing -- when the policy is already current.
"$SCRIPT_DIR/install_selinux_policy.sh" ||
    echo "warning: SELinux policy refresh failed; continuing." >&2

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
