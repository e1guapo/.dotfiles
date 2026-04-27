#!/bin/bash
# Screen locker wrapper for i3lock.
#
# The external DP-MST monitor flickers if DPMS powers the display down during
# the first moments of a lock cycle. Keep DPMS disabled only for a short grace
# window after locking, then restore the previous state so long-running lock
# sessions can still turn the monitor off normally.

set -u
LOCK_DPMS_GRACE_SECONDS="${LOCK_DPMS_GRACE_SECONDS:-15}"

restore_dpms() {
    if [[ -z ${DPMS_STATE_SAVED:-} ]]; then
        return
    fi

    if [[ ${DPMS_ENABLED:-yes} == yes ]]; then
        xset +dpms
        xset dpms "$DPMS_STANDBY" "$DPMS_SUSPEND" "$DPMS_OFF"
    else
        xset -dpms
    fi
}

save_dpms() {
    local vals

    vals=$(xset q | awk '/Standby:/ {print $2, $4, $6}')
    read -r DPMS_STANDBY DPMS_SUSPEND DPMS_OFF <<<"$vals"

    if xset q | grep -q "DPMS is Enabled"; then
        DPMS_ENABLED=yes
    else
        DPMS_ENABLED=no
    fi

    DPMS_STATE_SAVED=1
}

sleep_lock_active() {
    [[ -e /dev/fd/${XSS_SLEEP_LOCK_FD:--1} ]]
}

cleanup() {
    if [[ -n ${restore_pid:-} ]]; then
        kill "$restore_pid" >/dev/null 2>&1 || true
        wait "$restore_pid" 2>/dev/null || true
    fi
    restore_dpms
}

schedule_dpms_restore() {
    (
        sleep "$LOCK_DPMS_GRACE_SECONDS"
        restore_dpms
    ) &
    restore_pid=$!
}

save_dpms
trap 'cleanup; [[ -n ${lock_pid:-} ]] && kill "$lock_pid" >/dev/null 2>&1 || true' INT TERM
trap cleanup EXIT

# Temporarily suppress DPMS to avoid a DP retrain flash during quick
# lock/unlock cycles.
xset +dpms
xset dpms 0 0 0

if sleep_lock_active; then
    # Start i3lock in the background so we can release the sleep-delay fd once
    # the lock is active.
    i3lock --nofork {XSS_SLEEP_LOCK_FD}<&- &
else
    i3lock --nofork &
fi
lock_pid=$!

schedule_dpms_restore

if sleep_lock_active; then
    sleep 1
    exec {XSS_SLEEP_LOCK_FD}<&-
fi

wait "$lock_pid"
