#!/bin/sh
# Install/refresh the SELinux policy that confines guix-daemon.
#
# Guix ships a policy module with each release, under
# <root-guix>/share/selinux/guix-daemon.cil.  `semodule -i` takes a one-time
# snapshot of that file, so once root runs `guix pull` the *loaded* module
# falls behind the daemon it confines: the newer daemon performs operations
# that the older policy never allowed, and builds fail with AVC denials under
# enforcing mode.  That is why a working setup breaks "shortly after".
#
# Re-run this after every `sudo -i guix pull`.  It is idempotent and skips the
# reinstall when nothing changed, so it is cheap to call from other scripts.
#
# Usage:
#   ./scripts/install_selinux_policy.sh                 # install if changed
#   ./scripts/install_selinux_policy.sh --force         # always reinstall
#   ./scripts/install_selinux_policy.sh --relabel-store # also restorecon /gnu/store

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL_CIL="$SCRIPT_DIR/../files/etc/selinux/guix-daemon-local.cil"
ROOT_GUIX="/var/guix/profiles/per-user/root/current-guix"
BASE_CIL="$ROOT_GUIX/share/selinux/guix-daemon.cil"
STAMP="/var/lib/misc/guix-selinux-policy.stamp"

FORCE=0
RELABEL_STORE=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --relabel-store) RELABEL_STORE=1 ;;
        *) printf 'install_selinux_policy: unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

if ! command -v semodule >/dev/null 2>&1; then
    echo 'install_selinux_policy: semodule not found; is policycoreutils installed?' >&2
    exit 1
fi

# Nothing to install against a disabled policy store.  Permissive still needs
# the module: that is how denials get logged instead of silently allowed.
if [ "$(getenforce 2>/dev/null || echo Disabled)" = "Disabled" ]; then
    echo 'SELinux is disabled; skipping policy install.'
    exit 0
fi

# The daemon runs out of root's guix profile, so root's copy of the policy is
# the one that matches the running binary -- not the user's ~/.config/guix.
if [ ! -f "$BASE_CIL" ]; then
    printf 'install_selinux_policy: missing upstream policy: %s\n' "$BASE_CIL" >&2
    printf 'Has root ever run `sudo -i guix pull`?\n' >&2
    exit 1
fi

if [ ! -f "$LOCAL_CIL" ]; then
    printf 'install_selinux_policy: missing local supplement: %s\n' "$LOCAL_CIL" >&2
    exit 1
fi

# Stamp both inputs so a new upstream policy (or an edit to our supplement)
# forces a reinstall, and an unchanged pair costs nothing.
want=$(cat "$BASE_CIL" "$LOCAL_CIL" | sha256sum | cut -d' ' -f1)
have=$(cat "$STAMP" 2>/dev/null || true)

if [ "$FORCE" -eq 0 ] && [ "$want" = "$have" ] && [ "$RELABEL_STORE" -eq 0 ]; then
    echo "SELinux policy for guix-daemon is already current; nothing to do."
    exit 0
fi

echo "Installing SELinux policy:"
printf '  upstream: %s\n' "$BASE_CIL"
printf '  local:    %s\n' "$LOCAL_CIL"

# Both modules go in one transaction: the supplement references types declared
# by the upstream block (guix_daemon.*), so it cannot link on its own.
sudo semodule -i "$BASE_CIL" "$LOCAL_CIL"

# Relabel the paths whose file contexts the policy defines.  /gnu/store is
# excluded by default -- it holds hundreds of thousands of files and its
# contents inherit the correct label at creation time.  Use --relabel-store
# after a restore, a filesystem move, or a full-system relabel.
echo "Restoring file contexts..."
sudo restorecon -R /var/guix /etc/guix 2>/dev/null || true
daemon_bin=$(readlink -f "$ROOT_GUIX/bin/guix-daemon" 2>/dev/null || true)
if [ -n "$daemon_bin" ]; then
    sudo restorecon "$daemon_bin"
fi

if [ "$RELABEL_STORE" -eq 1 ]; then
    echo "Relabeling /gnu/store (slow)..."
    sudo restorecon -R /gnu/store
fi

sudo mkdir -p "$(dirname "$STAMP")"
printf '%s' "$want" | sudo tee "$STAMP" >/dev/null

# A policy reload applies to the running daemon immediately, but a *label*
# change on the binary only takes effect on exec.  Restart if the daemon is
# not currently in its own domain.
if ! ps -eZ | grep -q 'guix_daemon\.guix_daemon_t.*guix-daemon'; then
    echo "guix-daemon is not running in guix_daemon_t; restarting it..."
    sudo systemctl restart guix-daemon
fi

echo
echo "Policy installed. Verify the previously denied accesses are now allowed:"
echo "  sesearch -A -s guix_daemon.guix_daemon_t -t fs_t -c filesystem"
echo "  sesearch -A -s guix_daemon.guix_daemon_t -t init_var_run_t -c dir"
echo "  sesearch -A -s guix_daemon.guix_daemon_t -t guix_daemon.guix_daemon_conf_t -c file"
echo
echo "Then return to enforcing:  sudo setenforce 1"
