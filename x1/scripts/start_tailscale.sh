#!/usr/bin/env bash
set -euo pipefail

sudo systemctl stop zstunnel.service zsaservice.service || true

sudo tailscale up --accept-dns=true --accept-routes=false --exit-node=
