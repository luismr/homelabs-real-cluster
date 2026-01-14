#!/bin/bash
# Fix kubeconfig after HA conversion (certificates may have changed)
# This script regenerates the kubeconfig from the cluster

set -euo pipefail

# Source cluster hosts if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "${SCRIPT_DIR}/scripts/cluster-hosts.env" ]; then
  source "${SCRIPT_DIR}/scripts/cluster-hosts.env"
fi

# Use first master IP (or default)
FIRST_MASTER_IP="${MASTER_IP:-192.168.7.200}"
SSH_USER="${SSH_USER:-ubuntu}"

echo "=== Fixing kubeconfig after HA conversion ==="
echo "Using master IP: ${FIRST_MASTER_IP}"
echo ""

# Check if we can SSH to the master
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${SSH_USER}@${FIRST_MASTER_IP}" "echo 'SSH OK'" 2>/dev/null; then
  echo "⚠️  Cannot SSH to ${FIRST_MASTER_IP}"
  echo "Please check:"
  echo "  1. SSH access is configured"
  echo "  2. MASTER_IP is correct in scripts/cluster-hosts.env"
  echo "  3. SSH key is added to authorized_keys"
  exit 1
fi

echo "✅ SSH connection OK"
echo ""

# Backup existing kubeconfig
if [ -f ~/.kube/config-homelabs ]; then
  echo "Backing up existing kubeconfig..."
  cp ~/.kube/config-homelabs ~/.kube/config-homelabs.backup.$(date +%Y%m%d_%H%M%S)
fi

# Get kubeconfig from master
echo "Fetching kubeconfig from master node..."
mkdir -p ~/.kube

# Try to get kubeconfig from any master node
ssh "${SSH_USER}@${FIRST_MASTER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' 2>/dev/null | \
  sed "s/127.0.0.1/${FIRST_MASTER_IP}/g" > ~/.kube/config-homelabs || {
  echo "❌ Failed to get kubeconfig from ${FIRST_MASTER_IP}"
  echo "Trying alternative method..."
  
  # Alternative: try getting from ubuntu user's config
  ssh "${SSH_USER}@${FIRST_MASTER_IP}" 'cat ~/.kube/config' 2>/dev/null | \
    sed "s/127.0.0.1/${FIRST_MASTER_IP}/g" > ~/.kube/config-homelabs || {
    echo "❌ Failed to get kubeconfig"
    exit 1
  }
}

chmod 600 ~/.kube/config-homelabs
echo "✅ Kubeconfig updated: ~/.kube/config-homelabs"
echo ""

# Test kubectl
export KUBECONFIG=~/.kube/config-homelabs
echo "Testing kubectl connection..."
if kubectl get nodes 2>&1 | head -5; then
  echo ""
  echo "✅ kubectl is working!"
else
  echo ""
  echo "⚠️  kubectl test failed. You may need to:"
  echo "  1. Accept the new certificate manually"
  echo "  2. Check cluster is running: ssh ${SSH_USER}@${FIRST_MASTER_IP} 'sudo systemctl status k3s'"
  echo "  3. Try: kubectl --insecure-skip-tls-verify get nodes"
fi

echo ""
echo "To use this kubeconfig:"
echo "  export KUBECONFIG=~/.kube/config-homelabs"
