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

**Step 2: Force a Thunderbolt rescan**

```sh
echo 1 | sudo tee /sys/bus/thunderbolt/devices/0-0/rescan
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
