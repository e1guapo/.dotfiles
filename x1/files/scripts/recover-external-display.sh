#!/usr/bin/env bash
# Recover a DisplayPort MST tunnel that is wedged behind the Thunderbolt dock.

set -euo pipefail

PROGRAM=${0##*/}
ASSUME_YES=0
DRIVER_DIR=/sys/bus/pci/drivers/thunderbolt
SETUP_SCRIPT=${DISPLAY_SETUP_SCRIPT:-"$HOME/scripts/setup-displays.sh"}

usage() {
  cat <<EOF
Usage: $PROGRAM [--yes]

Rebind the Thunderbolt controller hosting the dock, wait for its DisplayPort
MST output, and run setup-displays.sh. Use --yes to skip the confirmation.
EOF
}

die() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

case ${1:-} in
  "") ;;
  -y|--yes) ASSUME_YES=1 ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
(( $# <= 1 )) || {
  usage >&2
  exit 2
}

command -v xrandr >/dev/null 2>&1 || die "xrandr is not installed"
command -v sudo >/dev/null 2>&1 || die "sudo is not installed"
[[ -x $SETUP_SCRIPT ]] || die "display setup script is not executable: $SETUP_SCRIPT"

XR=$(xrandr --query 2>&1) || die "xrandr failed; run this from the graphical session: $XR"
EXTERNAL=$(printf '%s\n' "$XR" | awk '/^DP-[0-9]+-[0-9]+ connected/ {print $1; exit}' || true)

if [[ -n $EXTERNAL ]]; then
  printf 'External display already detected as %s; applying display layout.\n' "$EXTERNAL"
  exec "$SETUP_SCRIPT"
fi

# Find a remote Thunderbolt device (N-M, where M is nonzero), preferring one
# whose advertised name identifies it as a dock. Its domain symlink tells us
# which PCI NHI controller must be rebound.
DOCK_DEVICE=
FALLBACK_DEVICE=
for candidate in /sys/bus/thunderbolt/devices/*; do
  [[ -e $candidate ]] || continue
  device_id=${candidate##*/}
  [[ $device_id =~ ^[0-9]+-[1-9][0-9]*(\.[0-9]+)*$ ]] || continue
  [[ -n $FALLBACK_DEVICE ]] || FALLBACK_DEVICE=$candidate

  device_name=$(cat -- "$candidate/device_name" 2>/dev/null || true)
  if [[ ${device_name,,} == *dock* ]]; then
    DOCK_DEVICE=$candidate
    break
  fi
done

[[ -n $DOCK_DEVICE ]] || DOCK_DEVICE=$FALLBACK_DEVICE
[[ -n $DOCK_DEVICE ]] || die "no connected Thunderbolt dock/device found"

device_id=${DOCK_DEVICE##*/}
domain_number=${device_id%%-*}
domain_path=$(readlink -f "/sys/bus/thunderbolt/devices/domain$domain_number")
[[ -n $domain_path ]] || die "could not resolve Thunderbolt domain $domain_number"

CONTROLLER=${domain_path%/*}
CONTROLLER=${CONTROLLER##*/}
[[ $CONTROLLER =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]$ ]] ||
  die "unexpected Thunderbolt controller path: $domain_path"
[[ -e $DRIVER_DIR/$CONTROLLER ]] ||
  die "Thunderbolt controller $CONTROLLER is not bound to the thunderbolt driver"

device_name=$(cat -- "$DOCK_DEVICE/device_name" 2>/dev/null || true)
printf 'Found %s on Thunderbolt controller %s.\n' "${device_name:-$device_id}" "$CONTROLLER"
printf 'Rebinding it will briefly disconnect dock USB, Ethernet, and audio.\n'

if (( ! ASSUME_YES )); then
  printf 'Continue? [y/N] '
  read -r reply || exit 1
  [[ $reply == [yY] || $reply == [yY][eE][sS] ]] || exit 0
fi

# Authenticate before unbinding so a password prompt cannot leave the
# controller detached. The EXIT trap makes a best-effort rebind on failure.
sudo -v
REBIND_PENDING=0
restore_controller() {
  if (( REBIND_PENDING )); then
    printf 'Attempting to restore Thunderbolt controller %s...\n' "$CONTROLLER" >&2
    if printf '%s\n' "$CONTROLLER" | sudo tee "$DRIVER_DIR/bind" >/dev/null; then
      REBIND_PENDING=0
    else
      printf '%s: controller %s remains unbound; reboot to recover it\n' \
        "$PROGRAM" "$CONTROLLER" >&2
    fi
  fi
}
trap restore_controller EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '%s\n' "$CONTROLLER" | sudo tee "$DRIVER_DIR/unbind" >/dev/null
REBIND_PENDING=1
sleep 3
printf '%s\n' "$CONTROLLER" | sudo tee "$DRIVER_DIR/bind" >/dev/null
REBIND_PENDING=0
trap - EXIT INT TERM

printf 'Waiting for the DisplayPort MST output...\n'
EXTERNAL=
for _ in {1..15}; do
  sleep 1
  XR=$(xrandr --query 2>/dev/null || true)
  EXTERNAL=$(printf '%s\n' "$XR" | awk '/^DP-[0-9]+-[0-9]+ connected/ {print $1; exit}' || true)
  [[ -z $EXTERNAL ]] || break
done

if [[ -z $EXTERNAL ]]; then
  die "Thunderbolt recovered, but no external MST display appeared; power-cycle the dock next"
fi

printf 'External display recovered as %s; applying display layout.\n' "$EXTERNAL"
exec "$SETUP_SCRIPT"
