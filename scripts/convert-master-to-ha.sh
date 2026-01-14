#!/bin/bash
# Convert existing single-master k3s cluster to HA mode with --cluster-init
# This must be run on the first master node

set -euo pipefail

echo "=== Converting k3s master to HA mode ==="
echo "⚠️  WARNING: This will temporarily disrupt the cluster!"
echo ""

# Get current master IP
MASTER_IP_ARG="${1:-}"
if [ -n "${MASTER_IP_ARG}" ]; then
  MASTER_IP="${MASTER_IP_ARG}"
else
  DEFAULT_IF=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')
  if [ -n "${DEFAULT_IF}" ]; then
    MASTER_IP=$(ip -4 -o addr show "${DEFAULT_IF}" | awk '{print $4}' | cut -d/ -f1 | head -n1)
  fi
  if [ -z "${MASTER_IP:-}" ]; then
    MASTER_IP=$(hostname -I | awk '{print $1}')
  fi
fi

if [ -z "${MASTER_IP}" ]; then
  echo "Failed to determine MASTER_IP" >&2
  exit 1
fi

echo "Master IP: ${MASTER_IP}"

# Generate a secure token
K3S_TOKEN=$(openssl rand -hex 32)
echo ""
echo "Generated K3S_TOKEN: ${K3S_TOKEN}"
echo "⚠️  SAVE THIS TOKEN - you'll need it to join other nodes!"
echo ""

# Uninstall existing k3s
echo "Uninstalling existing k3s..."
sudo /usr/local/bin/k3s-uninstall.sh || true

# Wait a bit
sleep 5

# Reinstall with cluster-init
echo "Installing k3s in HA mode with --cluster-init..."
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sudo sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-ip "${MASTER_IP}" \
  --node-external-ip "${MASTER_IP}" \
  --bind-address "${MASTER_IP}" \
  --advertise-address "${MASTER_IP}" \
  --tls-san "${MASTER_IP}" \
  --cluster-init

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
until sudo kubectl get nodes &>/dev/null; do
  sleep 2
done

# Set up kubectl access
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo ""
echo "=== Master converted to HA mode successfully ==="
echo "K3S_TOKEN: ${K3S_TOKEN}"
echo "Save this token to convert other nodes to control plane!"
echo ""
echo "Current nodes:"
sudo kubectl get nodes -o wide
