#!/usr/bin/env bash
set -euo pipefail

INTERNAL="eDP-1"
TARGET_MODE="3840x1600"
TARGET_RATE="60"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/display-setup"
LOG_FILE="$LOG_DIR/display-setup.log"
TAG="display-setup"

mkdir -p "$LOG_DIR"

ts() { date '+%F %T%z'; }

log() {
  local msg="$*"
  printf '%s %s\n' "$(ts)" "$msg" >> "$LOG_FILE"
  # Also to the systemd journal (best effort)
  command -v logger >/dev/null 2>&1 && logger -t "$TAG" -- "$msg" || true
}

die() {
  log "ERROR: $*"
  exit 1
}

log "---- run start (pid=$$, tty=${TTY:-none}, display=${DISPLAY:-unset}) ----"

XR=$(xrandr --query 2>&1) || die "xrandr failed: $XR"

# Pick the first connected MST sink (DP-*-*)
EXTERNAL=$(printf "%s\n" "$XR" | awk '/^DP-[0-9]+-[0-9]+ connected/ {print $1; exit}' || true)

if [ -z "${EXTERNAL:-}" ]; then
  log "no external MST output detected; exiting"
  exit 0
fi

geo_from_line() {
  awk '{
    for (i=1;i<=NF;i++)
      if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) { print $i; exit }
  }'
}

ILINE=$(printf "%s\n" "$XR" | awk -v o="$INTERNAL" '$1==o {print; exit}' || true)
ELINE=$(printf "%s\n" "$XR" | awk -v o="$EXTERNAL" '$1==o {print; exit}' || true)

[ -n "${ILINE:-}" ] || die "internal output $INTERNAL not found in xrandr output"
[ -n "${ELINE:-}" ] || die "external output $EXTERNAL not found in xrandr output"

IGEO=$(printf "%s\n" "$ILINE" | geo_from_line || true)
EGEO=$(printf "%s\n" "$ELINE" | geo_from_line || true)

log "detected: internal=$INTERNAL line='$ILINE' geo='${IGEO:-none}'"
log "detected: external=$EXTERNAL line='$ELINE' geo='${EGEO:-none}'"

[ -n "${IGEO:-}" ] || die "could not parse internal geometry for $INTERNAL"

# Compute desired external position: right-of internal
IW=${IGEO%%x*}
REST=${IGEO#*x}
REST=${REST#*+}
IX=${REST%%+*}
IY=${REST#*+}

DX=$((IX + IW))
DY=$IY
WANT_GEO="${TARGET_MODE}+${DX}+${DY}"

log "desired: external mode=${TARGET_MODE}@${TARGET_RATE} pos=${DX}x${DY} want_geo=${WANT_GEO}"

# If external is enabled and already at desired geometry, do nothing
if [ -n "${EGEO:-}" ] && [ "$EGEO" = "$WANT_GEO" ]; then
  log "no-op: external already configured (${EGEO})"
  exit 0
fi

log "apply: configuring external (was '${EGEO:-disabled}') -> '$WANT_GEO'"

# Minimal touch: just ensure primary, then set external mode/pos
xrandr --output "$INTERNAL" --primary
xrandr --output "$EXTERNAL" --mode "$TARGET_MODE" --rate "$TARGET_RATE" --pos "${DX}x${DY}"

log "apply: done"
