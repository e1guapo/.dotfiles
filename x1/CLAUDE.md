# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles + Guix Home manifest for a Lenovo ThinkPad X1 Carbon running the Fedora 42 i3 Spin. The full initial-setup walkthrough lives in `README.md`; recurring fixes for this specific hardware (Thunderbolt dock, lid-close poweroff) live in `TROUBLESHOOTING.md`. Read those before changing anything power- or display-related.

## Core commands

- `./scripts/reconfigure.sh` — `guix home reconfigure config/home/home-configuration.scm`. Run this after editing the manifest or anything under `files/` (the dotfiles tree is deployed by Guix Home, not symlinked manually).
- `./scripts/update-channels.sh` — `guix pull` against `files/.config/guix/base-channels.scm`, then reconfigure, then snapshot the resolved channels to `files/.config/guix/channels.scm`. Rolls back the pull on reconfigure failure. Use this (not `reconfigure.sh`) when intentionally updating package versions.
- `~/scripts/install_keyd_config.sh` — re-run only when `files/etc/keyd/default.conf` or `files/etc/systemd/system/keyd.service` change, or when root's `keyd` install path moves. Installs keyd via `sudo -i guix install keyd` if root lacks it.
- `./scripts/install_logind_lid_policy.sh` — installs `files/etc/systemd/logind.conf.d/50-lid-switch.conf` into `/etc/`.
- `./scripts/install_selinux_policy.sh` — reinstalls the `guix-daemon` SELinux module (upstream's `.cil` from root's guix + `files/etc/selinux/guix-daemon-local.cil`). Idempotent, stamped by checksum, so it's a silent no-op when current; `reconfigure.sh` and `update-channels.sh` both call it first. Re-run manually after `sudo -i guix pull`.

There is no build/test/lint target — this is a config repo.

## Architecture

The repo has three deployment pathways, and which one applies depends on the file's location. Getting this wrong means a change looks deployed but isn't.

**1. Guix-managed user packages + env (`config/home/home-configuration.scm`)**
The single source of truth for: installed packages, `PATH`/env vars, bash aliases, which bashrc snippets to source, and XDG autostart entries. Edit the manifest, then `./scripts/reconfigure.sh`. The `(bashrc ...)` list enumerates which files under `files/.bash_config_files/` actually get sourced — adding a new `*.bashrc` file alone does nothing until it's listed there.

**2. User dotfiles tree (`files/` → `$HOME`)**
Deployed by `home-dotfiles-service-type` in the manifest (`(directories '("../../files"))`). Anything under `files/` lands at the corresponding path in `$HOME` after reconfigure. That means:
- `files/.config/i3/config` → `~/.config/i3/config`
- `files/scripts/lock.sh` → `~/scripts/lock.sh` (referenced directly from the i3 config as `~/scripts/...`)
- `files/bin/browser` → `~/bin/browser`

**3. System files staged in `files/etc/` (NOT auto-deployed)**
`files/etc/` is a *source tree* for system-level config that requires `sudo install` via an explicit installer script. Guix Home does not touch `/etc`. Editing a file under `files/etc/` has zero effect until its installer is re-run (`install_keyd_config.sh`, `install_logind_lid_policy.sh`, `install_selinux_policy.sh`). Treat these like a Makefile with manual targets. (`files/etc/selinux/guix-daemon-local.cil` is the one exception to the "copied into `/etc`" pattern — `semodule -i` loads it into the policy store instead.)

Autostart `.desktop` entries (flameshot shortcuts, XFCE power config) are generated inline in the manifest via `plain-file` and registered through `home-xdg-configuration-files-service-type`, not stored as files in the tree. To change them, edit the `define` near the top of `home-configuration.scm`.

`scripts/` (top-level) holds one-shot host-setup helpers that are run directly from the repo. `files/scripts/` holds scripts that get deployed to `~/scripts/` and are invoked at runtime from `i3/config` and autostart `.desktop` entries. Don't confuse the two — moving a script between them changes when and how it runs.

## Non-obvious constraints

- **Lid/sleep/hibernate button actions must be `1` (suspend).** Values `3` (hibernate) or `4` (shutdown) cause the machine to poweroff instead of suspend, because hibernate is blocked by kernel lockdown under Secure Boot and systemd falls back to poweroff. `configure_xfce_power.sh` enforces this on every login; `50-lid-switch.conf` enforces it at the logind level. Do not "simplify" either.
- **The SELinux fix is a *refresh*, not a bigger ruleset.** Guix's shipped `guix-daemon.cil` gains rules every release; `semodule -i` snapshots it once, so the loaded module drifts behind the daemon after each root `guix pull` and builds start failing under enforcing. Before adding anything to `guix-daemon-local.cil`, check the shipped `.cil` (`grep`) against the loaded policy (`sesearch -A -s guix_daemon.guix_daemon_t ...`) — if the rule exists upstream, the answer is to re-run the installer. Never paste `audit2allow -M` output in wholesale.
- **Do not add `python-pip` to the Guix manifest.** System-managed pip conflicts with user upgrades and breaks vendored dependencies. Use `uv` or `python -m venv` instead (see README).
- **`lock.sh` deliberately disables DPMS for a short grace window** (`LOCK_DPMS_GRACE_SECONDS`, default 15s) to avoid a DP-MST flash on the Thunderbolt dock, then restores the prior DPMS state. It also honors `XSS_SLEEP_LOCK_FD` when invoked by `xss-lock --transfer-sleep-lock`. Don't replace with a bare `i3lock` call.
- **Tailscale coexistence with Zscaler:** `start_tailscale.sh` stops `zstunnel`/`zsaservice` before `tailscale up`; `stop_tailscale.sh` does the reverse. Running `tailscale up` directly without stopping Zscaler will fail or route incorrectly.
- **`setup-displays.sh` is idempotent and logs to `~/.local/state/display-setup/`.** It's wired to i3 startup and `Mod+m`. For dock/external-monitor issues follow the ordered recovery steps in `TROUBLESHOOTING.md` before touching the script.
