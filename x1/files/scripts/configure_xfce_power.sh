#!/bin/sh
# Configure XFCE Power Manager settings.
# Enables logind lid switch handling to fix screen lock on lid close.

set -eu

XFCONF_QUERY=$(command -v xfconf-query || true)
if [ -z "$XFCONF_QUERY" ]; then
    printf 'configure_xfce_power: xfconf-query not found; skipping\n' >&2
    exit 0
fi

CHANNEL="xfce4-power-manager"

set_property() {
    prop=$1
    type=$2
    value=$3

    for attempt in 1 2 3 4 5; do
        if "$XFCONF_QUERY" -c "$CHANNEL" -p "$prop" >/dev/null 2>&1; then
            if "$XFCONF_QUERY" -c "$CHANNEL" -p "$prop" -t "$type" -s "$value"; then
                return 0
            fi
        else
            if "$XFCONF_QUERY" -c "$CHANNEL" -p "$prop" -n -t "$type" -s "$value"; then
                return 0
            fi
        fi
        sleep 1
    done

    printf 'configure_xfce_power: failed to set %s after retries\n' "$prop" >&2
    return 1
}

# Let systemd logind handle lid switch (cleanest for i3 + xss-lock).
set_property '/xfce4-power-manager/logind-handle-lid-switch' 'bool' 'true'

# Display Power Management (DPMS) timeouts in minutes
set_property '/xfce4-power-manager/dpms-on-ac-sleep' 'uint' '15'
set_property '/xfce4-power-manager/dpms-on-ac-off' 'uint' '20'
set_property '/xfce4-power-manager/dpms-on-battery-sleep' 'uint' '30'
set_property '/xfce4-power-manager/dpms-on-battery-off' 'uint' '40'

# Performance profile on AC power
set_property '/xfce4-power-manager/profile-on-ac' 'string' 'performance'

exit 0
