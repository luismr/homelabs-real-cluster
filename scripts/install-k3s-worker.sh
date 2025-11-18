#!/bin/bash
# Install k3s worker node

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <MASTER_IP> <NODE_TOKEN>"
  exit 1
fi

MASTER_IP=$1
NODE_TOKEN=$2

# Determine primary IPv4 address on the interface with default route
DEFAULT_IF=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')
if [ -n "${DEFAULT_IF}" ]; then
  NODE_IP=$(ip -4 -o addr show "${DEFAULT_IF}" | awk '{print $4}' | cut -d/ -f1 | head -n1)
fi
if [ -z "${NODE_IP:-}" ]; then
  NODE_IP=$(hostname -I | awk '{print $1}')
fi

echo "=== Installing k3s worker on $HOSTNAME (${NODE_IP}) ==="
echo "Joining cluster at: $MASTER_IP"

# Install k3s agent
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" \
  K3S_TOKEN="${NODE_TOKEN}" sudo sh -s - agent \
  --node-ip "${NODE_IP}" \
  --node-external-ip "${NODE_IP}"

echo "=== k3s worker installed successfully ==="

