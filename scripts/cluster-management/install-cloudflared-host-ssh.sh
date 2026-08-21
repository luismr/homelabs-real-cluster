#!/usr/bin/env bash
# Install cloudflared on Ubuntu (deb) and register the systemd connector for a NEW tunnel token.
# Use a token from Zero Trust > Networks > Tunnels > your SSH-only tunnel (NOT the K8s/terraform token).
#
# Prefer env var to avoid token in shell history:
#   CLOUDFLARED_HOST_TUNNEL_TOKEN='eyJ...' sudo -E ./install-cloudflared-host-ssh.sh
# Or:
#   sudo ./install-cloudflared-host-ssh.sh 'eyJ...'

set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

TOKEN="${CLOUDFLARED_HOST_TUNNEL_TOKEN:-${1:-}}"
if [[ -z "${TOKEN}" ]]; then
  echo "Missing tunnel token." >&2
  echo "Set CLOUDFLARED_HOST_TUNNEL_TOKEN or pass the token as the first argument." >&2
  echo "Create a dedicated tunnel in Cloudflare Zero Trust; do not reuse the in-cluster Terraform token." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

if command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is already installed:"
  cloudflared --version
else
  echo "Adding Cloudflare package repository..."
  install -d -m 0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg -o /usr/share/keyrings/cloudflare-main.gpg
  chmod 0644 /usr/share/keyrings/cloudflare-main.gpg
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' >/etc/apt/sources.list.d/cloudflared.list
  apt-get update -qq
  apt-get install -y cloudflared
fi

echo "Installing systemd service (cloudflared connector)..."
cloudflared service install "${TOKEN}"

systemctl enable cloudflared
systemctl restart cloudflared

sleep 2
if systemctl is-active --quiet cloudflared; then
  echo "cloudflared.service is active."
  systemctl status cloudflared --no-pager -l || true
else
  echo "cloudflared.service failed to stay active. Check: journalctl -u cloudflared -e" >&2
  exit 1
fi
