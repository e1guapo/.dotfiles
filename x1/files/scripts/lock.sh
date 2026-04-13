#!/bin/sh
# Screen locker wrapper for i3lock.
#
# Problem: the external DP-MST monitor (DP-1-3) flickers on unlock because
# DPMS issues a standby/off signal during the lock session, which triggers
# DisplayPort link re-training on wake. The internal eDP-1 panel is immune
# to this because it has no link negotiation step.
#
# Fix: disable DPMS auto-timers for the duration of the lock, then restore
# them after unlock. This preserves monitor power-saving during normal idle
# while preventing the DP flicker on unlock.

# Save current DPMS timeouts before locking
DPMS_VALS=$(xset q | awk '/Standby:/ {print $2, $4, $6}')
STANDBY=$(echo "$DPMS_VALS" | cut -d' ' -f1)
SUSPEND=$(echo "$DPMS_VALS" | cut -d' ' -f2)
OFF=$(echo "$DPMS_VALS" | cut -d' ' -f3)

# Disable DPMS auto-timers for lock duration
xset dpms 0 0 0

# Run i3lock (blocks until unlock)
i3lock --nofork

# Restore DPMS timers after unlock
xset dpms "$STANDBY" "$SUSPEND" "$OFF"
