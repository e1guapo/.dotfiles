#!/usr/bin/env bash
set -euo pipefail

sudo systemctl stop zstunnel.service zsaservice.service || true

if resolvectl dns | grep -q 'zcctun0: 100.64.0.2'; then
  sudo resolvectl revert zcctun0
fi

sudo tailscale up --accept-dns=true --accept-routes=false --exit-node=

#resolvectl dns
#resolvectl domain
#systemctl is-active zstunnel.service zsaservice.service
