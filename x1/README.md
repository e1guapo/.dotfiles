# System setup
This setup is for a Lenovo ThinkPad X1 Carbon running Fedora i3 Spin (Fedora 42).

## packages/management
- notifications: `dunst`
- config: `lxappearance`, `xfce4-settings`, `xfce4-power-manager`
- bluetooth: `blueman-applet` (blueman)
- network: `nm-applet` (network-manager-applet)
- screenshot: `flameshot`
- lockscreen signal: `xset`
- program launcher: `dmenu`

## Install basic packages

### Install packages using native package manager (`dnf`)
- install `lxappearance` - configure system settings (like font size)
- Install `bolt` - kernel driver for thunderbolt
- Install power/settings management apps
- Install flatpak
- Install virtualization group
- SELinux analysis tools
- Cross-platform compilation/analysis tools for arm and aarch64
```
sudo dnf install -y lxappearance bolt blueman xfce4-settings xfce4-power-manager
sudo dnf install -y flatpak @virtualization setools-console
sudo dnf install -y binutils-aarch64-linux-gnu.x86_64 gcc-aarch64-linux-gnu.x86_64
sudo dnf install -y binutils-arm-linux-gnu.x86_64 gcc-arm-linux-gnu.x86_64
```
Install terraform
```
wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo

# Check whether the repo is enabled
sudo dnf repolist | grep -i hashicorp

# Check whether terraform is visible in that repo
sudo dnf repoquery --repoid=hashicorp terraform
sudo dnf -y install terraform
```

### Install keyd (Guix on Fedora)
Apply dotfiles and install keyd config/service:
```
guix home reconfigure /home/dennis/.dotfiles/x1/config/home/home-configuration.scm
~/scripts/install_keyd_config.sh
sudo systemctl status keyd --no-pager
```

`~/scripts/install_keyd_config.sh` installs `keyd` via `sudo -i guix install keyd` if root does not already have it.

Run `~/scripts/install_keyd_config.sh` one time for initial setup, then rerun only when:
- `files/etc/keyd/default.conf` changes
- `files/etc/systemd/system/keyd.service` changes
- root's keyd install path changes (for example after reinstall)

### Power Management Configuration

XFCE Power Manager settings are automatically configured via `files/scripts/configure_xfce_power.sh` (runs at login).

**Managed settings:**
- `logind-handle-lid-switch: true` - Enables systemd logind to handle lid close events. This allows xss-lock to properly lock the screen with i3lock before suspend, preventing "screen lock failed" errors.
- `dpms-on-ac-sleep: 0` - Never sleep display when on AC power
- `dpms-on-ac-off: 0` - Never turn off display when on AC power
- `dpms-on-battery-sleep: 30` - Sleep display after 30 minutes on battery
- `dpms-on-battery-off: 40` - Turn off display after 40 minutes on battery
- `profile-on-ac: performance` - Use performance profile when plugged in

**Note:** Lid actions (`lid-action-on-ac`, `lid-action-on-battery`) should be left unset in XFCE since logind handles all lid close behavior.

**Logind lid policy (system-level):**
- Install `files/etc/systemd/logind.conf.d/50-lid-switch.conf` to `/etc/systemd/logind.conf.d/` to suspend on lid close, but ignore lid events on AC power or when docked.
  - Helper: run `scripts/install_logind_lid_policy.sh` to install the drop-in, then restart logind or reboot.

**Other settings** (configured manually via GUI, not managed by script):
- Brightness levels, button actions, etc. can be adjusted using `xfce4-power-manager-settings` GUI

### Install obsidian, yubikey authenticator.
```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub md.obsidian.Obsidian
flatpak install com.yubico.yubioath
```

### Fix graphics for second monitor
1. Remove nomodeset if it exists
```
sudo grubby --update-kernel=ALL --remove-args="nomodeset"
```

2. Add `force_probe` for Lunar Lake GPU
```
sudo grubby --update-kernel=ALL --args="i915.force_probe=64a0 xe.force_probe=64a0"
sudo reboot
```

### adjust lightdm font/size
adding the following to `/etc/lightdm/lightdm-gtk-greeter.conf`
```
[greeter]
font-name = Sans 18
xft-dpi = 120
```

### Then restart the service
```
sudo systemctl restart lightdm
```

### remove `plymouth` for text-based boot/luks prompt (needed for my new thinkpad)
1. Remove Plymouth package completely
```
sudo dnf remove plymouth plymouth-*
```

2. Update `GRUB_CMDLINE_LINUX`:
    - remove these parameters:
        - `rhgb`
        - `quiet`
    - add this parameter:
        - `rd.luks.options=none`

_note: No need for `plymouth.enable=0` since Plymouth is gone._

3. Regenerate GRUB config.
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

4. Regenerate initramfs without Plymouth.
```
sudo dracut -f
```

### Install uv and brave browser
```
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -fsS https://dl.brave.com/install.sh | sh
```

_Change startup for brave to increase font size with the `--force-device-scale-factor=2` parameter. We currently do this with a wrapper script: `~/bin/browser`._

### Python Environment Management

**Do NOT install `python-pip` via Guix.** System-managed pip conflicts with user upgrades and breaks vendored dependencies.

Instead, use one of these approaches:

1. **uv** (recommended, already installed):
   ```bash
   uv venv my-project
   source my-project/bin/activate
   uv pip install <packages>
   ```

2. **Python's built-in venv**:
   ```bash
   python -m venv my-env
   source my-env/bin/activate
   pip install <packages>  # pip included automatically
   ```

Both methods create isolated environments with their own pip installation.

### install guix
```
wget 'https://git.savannah.gnu.org/gitweb/?p=guix.git;a=blob_plain;f=etc/guix-install.sh;hb=HEAD'
chmod +x guix-install.sh
sudo ./guix-install.sh
```

### set up selinux policy for guix
`https://guix.gnu.org/manual/devel/en/html_node/SELinux-Support.html`


### Configure network access for guix daemon/container

### Set up virtualization
`https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/\#\_enabling\_hardware\_virtualization\_support`

### fix boot legibility
1. Change GRUB to make the GRUB menu legible. First, generate a font:
```
sudo grub2-mkfont --output=/boot/grub2/fonts/DejaVuSansMono32.pf2 \
  --size=32 /usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono.ttf
```

2. Then edit /etc/default/grub to include the following.
```
GRUB_TERMINAL_OUTPUT="gfxterm"
GRUB_FONT=/boot/grub2/fonts/DejaVuSansMono32.pf2
```

3. Then run:
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

4. Edit `/etc/vconsole.conf` to change the font (controls boot logs and LUKS prompt after GRUB). Change the font line to:
```
FONT=latarcyrheb-sun32
```

5. Then regenerate the `initramfs` so the font is available during early boot:
```
sudo dracut -f
```

6. Reboot to verify that everything worked.
