#!/bin/bash
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Refresh the guix-daemon SELinux policy if root's guix shipped a newer one.
# A stale module makes builds fail with AVC denials under enforcing.  This is a
# no-op -- and prompts for nothing -- when the policy is already current.
"$SCRIPT_DIR/install_selinux_policy.sh" ||
    echo "warning: SELinux policy refresh failed; continuing." >&2

guix home reconfigure config/home/home-configuration.scm
