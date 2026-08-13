# X1 Troubleshooting

## External Monitor Not Detected (Thunderbolt Dock)

The ThinkPad X1 uses a Thunderbolt 3 dock (Lenovo ThinkPad TB3 Dock) with DisplayPort
tunneling through Thunderbolt. After a reboot or unexpected shutdown, the DP tunnel
may fail to establish, causing the external monitor to not appear in `xrandr`.

### Symptoms

- `xrandr` shows only `eDP-1` connected; `DP-1`, `DP-2`, `HDMI-1` all disconnected
- No `DP-X-Y` (MST sub-connector) entries appear
- `dmesg | grep thunderbolt` shows: `DP: not active, tearing down`

### Fix (try in order)

**Step 1: Reseat the Thunderbolt cable**

Unplug the Thunderbolt/USB-C cable from the laptop side, wait 5 seconds, plug it
back in. Then check:

```sh
xrandr --query | grep "^DP"
```

If a `DP-X-Y connected` line appears, run:

```sh
~/scripts/setup-displays.sh
```

**Step 2: Rebind the Thunderbolt device**

The `/sys/bus/thunderbolt/devices/0-0/rescan` sysfs file was removed in kernel 6.19+. Use driver rebind instead:

```sh
echo 0-1 | sudo tee /sys/bus/thunderbolt/drivers/thunderbolt/unbind
sleep 2
echo 0-1 | sudo tee /sys/bus/thunderbolt/drivers/thunderbolt/bind
sleep 3
xrandr --query | grep "^DP"
```

If a connected display appears, run `~/scripts/setup-displays.sh`.

**Step 3: Reload the xe (GPU) driver**

This briefly disrupts the internal display.

```sh
sudo modprobe -r xe && sudo modprobe xe
sleep 3
xrandr --query | grep "^DP"
```

Then run `~/scripts/setup-displays.sh` if the display appeared.

**Step 4: Full power cycle the dock**

Unplug the dock's power supply, wait 10 seconds, reconnect power, then reconnect
the Thunderbolt cable. Check with `xrandr` as above.

**Step 5: Reboot**

If nothing else works:

```sh
sudo reboot
```

### Diagnostics

Useful commands when debugging:

```sh
# Check Thunderbolt device status
boltctl list

# Check DP tunnel status
sudo dmesg | grep -i "thunderbolt.*DP"

# Check DRM connector status
cat /sys/class/drm/*/status

# Check kernel display messages
journalctl -b 0 -k | grep -iE "drm|xe|display|hdmi|dp-|connector"

# Full xrandr state
xrandr --verbose
```

## Unexpected Shutdown Instead of Suspend

### Cause

When the lid is closed, the system attempts to hibernate. Hibernation is blocked
by kernel lockdown (Secure Boot), so systemd falls back to **powering off**.

### Fix

1. Install the logind override (prevents hibernate on lid close):

   ```sh
   ./files/scripts/install_logind_lid_policy.sh
   ```

2. Fix xfce4-power-manager actions (changes hibernate/shutdown to suspend):

   ```sh
   ./files/scripts/configure_xfce_power.sh
   ```

3. Verify:

   ```sh
   # Should show "suspend"
   busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
     org.freedesktop.login1.Manager HandleLidSwitch

   # Should show lid-action values of 1 (suspend), not 4 (shutdown)
   xfconf-query -c xfce4-power-manager -l -v | grep lid
   ```

## Guix Reconfigure Fails Until SELinux Is Set Permissive

### Symptoms

`guix home reconfigure` (or any build) fails under enforcing mode and succeeds
after `sudo setenforce 0`. Setting the policy up per the Guix manual fixes it
for a while, then it breaks again.

### Cause

`semodule -i` takes a **one-time snapshot** of the policy Guix ships at
`/var/guix/profiles/per-user/root/current-guix/share/selinux/guix-daemon.cil`.
Each Guix release adds rules to that file. When root runs `guix pull`, the
daemon moves forward but the loaded module does not, so the newer daemon
performs operations the older policy never allowed. That is the recurrence:
the policy is drifting behind the binary it confines, one `guix pull` at a time.

Confirm the drift by diffing shipped against loaded:

```sh
# shipped
grep -n 'fs_t' /var/guix/profiles/per-user/root/current-guix/share/selinux/guix-daemon.cil
# loaded
sesearch -A -s guix_daemon.guix_daemon_t -t fs_t -c filesystem
```

A rule present in the first and absent from the second means the module is
stale, **not** that upstream is missing a rule.

### Fix

```sh
./scripts/install_selinux_policy.sh
sudo setenforce 1
```

The script reinstalls upstream's policy plus
`files/etc/selinux/guix-daemon-local.cil` (rules upstream genuinely lacks),
restores file contexts, and stamps a checksum of both inputs at
`/var/lib/misc/guix-selinux-policy.stamp`. `reconfigure.sh` and
`update-channels.sh` call it first, so drift gets corrected before the build
that would have tripped over it. Re-run it manually after
`sudo -i guix pull`.

### Diagnosing a new denial

Set permissive so denials are logged rather than blocking, reproduce, then
read the log:

```sh
sudo setenforce 0
./scripts/reconfigure.sh
sudo ausearch -m AVC,USER_AVC -ts recent | audit2allow -w
sudo setenforce 1
```

Check the shipped `.cil` first. Only if the rule is absent there does it belong
in `guix-daemon-local.cil` — hand-translated to CIL and commented with why.
Do not pipe `audit2allow -M` output straight into the policy; it grants
whatever happened to get logged.

### Label drift

Labels are separate from rules and rarely the problem — new store items inherit
`guix_store_content_t` from `/gnu/store` at creation. After a restore, disk
migration, or full-system relabel, fix them with:

```sh
./scripts/install_selinux_policy.sh --relabel-store
```

That relabels all of `/gnu/store`, which is slow, so it is opt-in.

## Bare `python3` Can't Import Guix Python Libraries

### Symptoms

Running a script directly (`python3 foo.py`, no venv active) fails with
`ModuleNotFoundError` for a package installed via the Guix manifest.

### Cause

By design, we do **not** export `PYTHONPATH` globally (it would shadow every
venv). Bare Guix `python3` therefore sees only stdlib, not profile
`site-packages`.

### Fix

Run project python inside a venv or `uv` env, not bare:

```sh
python3 -m venv .venv && source .venv/bin/activate
pip install <deps>          # or: uv pip install <deps>
python3 foo.py
```

If a script genuinely needs a Guix-installed lib without a venv, prefix that
one command only (don't re-add the global export):

```sh
PYTHONPATH="$GUIX_PYTHONPATH" python3 foo.py
```

Note: Guix python **apps** (`aws`, `ranger`, `meld`) should work without this —
their wrappers export `GUIX_PYTHONPATH` themselves. If one of them fails, see
the next section.

## Guix Python Apps Fail with `ModuleNotFoundError`

### Symptoms

`ranger` (or `meld`, `aws`, any Guix python application) aborts on launch:

```
File ".../ranger-1.9.4/bin/.ranger-real", line 36, in <module>
    import ranger
ModuleNotFoundError: No module named 'ranger'
```

but works with user site-packages disabled:

```sh
PYTHONNOUSERSITE=1 ranger --version   # succeeds
```

### Cause

Guix python apps are shell wrappers that export `GUIX_PYTHONPATH`. The
interpreter does not read that variable natively — Guix's own
`sitecustomize.py`, shipped in the interpreter's store `site-packages`, is
what converts it into `sys.path` entries.

Python imports **only the first** `sitecustomize` module found on `sys.path`,
and `~/.local/lib/python3.11/site-packages` comes *before* the store
`site-packages`. So a `sitecustomize.py` deployed into the user
site-packages silently disables `GUIX_PYTHONPATH` for every Guix python app.

### Fix

Never name a local hook `sitecustomize.py`. Use
`files/.local/lib/python3.11/site-packages/usercustomize.py` — Python imports
`usercustomize` right after `sitecustomize`, so Guix's path setup runs *and*
the local hook runs. Then `./scripts/reconfigure.sh`.

This is unrelated to the global `PYTHONPATH` export removal above;
re-adding that export would mask this bug while re-breaking venv isolation.
