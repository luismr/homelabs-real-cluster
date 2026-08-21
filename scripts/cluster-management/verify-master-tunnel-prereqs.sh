#!/usr/bin/env bash
# Run on the k3s master (or: ssh ubuntu@<MASTER_IP> 'bash -s' < verify-master-tunnel-prereqs.sh)
# Checks prerequisites for host-level Cloudflare Tunnel (SSH connector).

set -euo pipefail

ok() { printf 'OK  %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*" >&2; }
bad() { printf 'FAIL %s\n' "$*" >&2; }

SSH_UNIT="ssh"
if ! systemctl cat "${SSH_UNIT}" &>/dev/null; then
  SSH_UNIT="sshd"
fi

if systemctl is-active --quiet "${SSH_UNIT}" 2>/dev/null; then
  ok "sshd unit active (${SSH_UNIT})"
else
  bad "sshd not active (tried ${SSH_UNIT})"
  exit 1
fi

if ss -tlnp 2>/dev/null | grep -qE ':22\b'; then
  ok "something listening on TCP 22"
  ss -tlnp 2>/dev/null | grep -E ':22\b' || true
else
  bad "no listener on TCP 22"
  exit 1
fi

if curl -sfI --connect-timeout 5 https://one.dash.cloudflare.com >/dev/null; then
  ok "outbound HTTPS to Cloudflare reachable"
else
  bad "cannot reach https://one.dash.cloudflare.com (check firewall/NAT)"
  exit 1
fi

if command -v cloudflared >/dev/null 2>&1; then
  cloudflared --version
  warn "cloudflared already installed; avoid two connectors using the same tunnel token"
else
  ok "cloudflared not installed (expected before host tunnel setup)"
fi

if [[ -f /home/ubuntu/.kube/config ]]; then
  ok "kubeconfig present at /home/ubuntu/.kube/config"
else
  warn "no /home/ubuntu/.kube/config (k3s may still use /etc/rancher/k3s/k3s.yaml with sudo kubectl)"
fi

echo ""
echo "Prerequisite check finished."
