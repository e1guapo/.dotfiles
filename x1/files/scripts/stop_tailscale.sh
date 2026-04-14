#!/usr/bin/env bash
set -euo pipefail

sudo tailscale down
sudo systemctl start zsaservice.service zstunnel.service
