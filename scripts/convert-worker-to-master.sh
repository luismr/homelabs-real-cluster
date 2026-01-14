#!/bin/bash
# Convert a worker node to a control plane node (master)
# Usage: convert-worker-to-master.sh <THIS_NODE_IP> <FIRST_MASTER_IP> <K3S_TOKEN>

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: $0 <THIS_NODE_IP> <FIRST_MASTER_IP> <K3S_TOKEN>"
  echo "Example: $0 192.168.7.201 192.168.7.200 K10abc123..."
  exit 1
fi

THIS_NODE_IP=$1
FIRST_MASTER_IP=$2
K3S_TOKEN=$3

echo "=== Converting worker to control plane node ==="
echo "This node IP: ${THIS_NODE_IP}"
echo "First master IP: ${FIRST_MASTER_IP}"
echo ""

# Uninstall existing k3s agent
echo "Uninstalling existing k3s agent..."
sudo /usr/local/bin/k3s-agent-uninstall.sh || true

# Wait a bit
sleep 5

# Install k3s server (control plane) joining the cluster
echo "Installing k3s server (control plane)..."
curl -sfL https://get.k3s.io | K3S_TOKEN="${K3S_TOKEN}" sudo sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-ip "${THIS_NODE_IP}" \
  --node-external-ip "${THIS_NODE_IP}" \
  --bind-address "${THIS_NODE_IP}" \
  --advertise-address "${THIS_NODE_IP}" \
  --tls-san "${THIS_NODE_IP}" \
  --server "https://${FIRST_MASTER_IP}:6443"

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
echo "=== Worker converted to control plane successfully ==="
echo "This node is now a master node!"
echo ""
echo "Current cluster nodes:"
sudo kubectl get nodes -o wide
