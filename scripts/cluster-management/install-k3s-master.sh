#!/bin/bash
# Install k3s master node with observability stack

set -euo pipefail

echo "=== Installing k3s master node ==="

# Master IP handling: use arg if provided, else auto-detect primary IPv4
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

# Install k3s server
curl -sfL https://get.k3s.io | sudo sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-ip "${MASTER_IP}" \
  --node-external-ip "${MASTER_IP}" \
  --bind-address "${MASTER_IP}" \
  --advertise-address "${MASTER_IP}" \
  --tls-san "${MASTER_IP}"

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
until sudo kubectl get nodes &>/dev/null; do
  sleep 2
done

echo "=== k3s master installed successfully ==="
echo "Node token:"
sudo cat /var/lib/rancher/k3s/server/node-token
echo ""
echo "Kubeconfig is available at: /etc/rancher/k3s/k3s.yaml"

# Set up kubectl access for ubuntu user
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
echo "kubectl config copied to /home/ubuntu/.kube/config for ubuntu user"

