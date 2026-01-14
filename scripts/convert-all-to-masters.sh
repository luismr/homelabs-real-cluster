#!/bin/bash
# Convert all nodes (including workers) to control plane nodes
# This makes every node capable of acting as a master

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Convert All Nodes to Control Plane (All Masters)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  WARNING: This will:"
echo "   1. Convert first master to HA mode (temporary disruption)"
echo "   2. Convert all worker nodes to control plane nodes"
echo "   3. All nodes will be able to act as masters"
echo ""

# Load configuration
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/cluster-hosts.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/cluster-hosts.env"
fi

# Defaults if not provided in env file
SSH_USER=${SSH_USER:-ubuntu}
SSH_KEY=${SSH_KEY:-}
SSH_EXTRA_OPTS=${SSH_EXTRA_OPTS:-}
FIRST_MASTER_IP=${MASTER_IP:-192.168.7.200}
WORKER_IPS=${WORKER_IPS:-"192.168.7.201 192.168.7.202 192.168.7.203"}

# Build arrays
read -r -a WORKER_IPS_ARR <<<"${WORKER_IPS}"

# SSH options
SSH_OPTS=("-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null")
if [ -n "${SSH_KEY}" ]; then
  SSH_OPTS+=("-i" "${SSH_KEY}")
fi
if [ -n "${SSH_EXTRA_OPTS}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARR=( ${SSH_EXTRA_OPTS} )
  SSH_OPTS+=("${EXTRA_ARR[@]}")
fi

echo "Configuration:"
echo "  First Master: ${FIRST_MASTER_IP}"
echo "  Workers to convert: ${WORKER_IPS}"
echo ""

read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Step 1: Convert first master to HA mode
echo ""
echo "[1/3] Converting first master to HA mode..."
echo "⚠️  Cluster will be temporarily unavailable..."

# Check if already in HA mode
IS_HA=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${FIRST_MASTER_IP}" \
  'sudo test -f /var/lib/rancher/k3s/server/db/etcd/config && echo "yes" || echo "no"' 2>/dev/null || echo "no")

if [ "${IS_HA}" = "no" ]; then
  echo "Converting first master to HA mode..."
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${FIRST_MASTER_IP}" \
    "bash -s -- ${FIRST_MASTER_IP}" < "${SCRIPT_DIR}/convert-master-to-ha.sh" | tee /tmp/k3s-ha-conversion.log
  
  # Extract token from output
  K3S_TOKEN=$(grep "K3S_TOKEN:" /tmp/k3s-ha-conversion.log | tail -1 | awk '{print $2}')
  
  if [ -z "${K3S_TOKEN}" ]; then
    echo "ERROR: Could not extract K3S_TOKEN from conversion output"
    echo "Please check the output above and manually extract the token"
    exit 1
  fi
  
  echo "Extracted K3S_TOKEN: ${K3S_TOKEN}"
else
  echo "✓ First master is already in HA mode"
  # Get existing token
  K3S_TOKEN=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${FIRST_MASTER_IP}" \
    'sudo cat /var/lib/rancher/k3s/server/node-token' 2>/dev/null)
  echo "Retrieved existing K3S_TOKEN"
fi

# Wait for cluster to stabilize
echo "Waiting for cluster to stabilize..."
sleep 15

# Step 2: Convert each worker to control plane
echo ""
echo "[2/3] Converting worker nodes to control plane..."
for WORKER_IP in "${WORKER_IPS_ARR[@]}"; do
  echo ""
  echo "  -> Converting ${WORKER_IP} to control plane..."
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${WORKER_IP}" \
    "bash -s -- ${WORKER_IP} ${FIRST_MASTER_IP} ${K3S_TOKEN}" \
    < "${SCRIPT_DIR}/convert-worker-to-master.sh"
  
  echo "  ✓ ${WORKER_IP} converted"
  sleep 10
done

# Step 3: Verify cluster
echo ""
echo "[3/3] Verifying cluster..."
export KUBECONFIG=~/.kube/config-homelabs
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${FIRST_MASTER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/${FIRST_MASTER_IP}/g" > ~/.kube/config-homelabs
chmod 600 ~/.kube/config-homelabs

echo ""
echo "All cluster nodes:"
kubectl get nodes -o wide

echo ""
echo "Control plane nodes:"
kubectl get nodes -l node-role.kubernetes.io/control-plane -o wide || kubectl get nodes

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Conversion Complete! 🎉                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "All nodes are now control plane nodes (masters):"
echo "  - ${FIRST_MASTER_IP} (first master)"
for WORKER_IP in "${WORKER_IPS_ARR[@]}"; do
  echo "  - ${WORKER_IP} (converted to master)"
done
echo ""
echo "✅ Benefits:"
echo "   - Any node can handle API requests"
echo "   - If one master goes down, others continue serving"
echo "   - When a master returns, it automatically rejoins"
echo ""
echo "⚠️  Notes:"
echo "   - All nodes now run control plane components (higher resource usage)"
echo "   - For kubectl access, use any master IP"
echo "   - Consider setting up a load balancer/VIP for better HA"
echo ""
echo "To test HA:"
echo "  1. Stop k3s on first master: ssh ${SSH_USER}@${FIRST_MASTER_IP} 'sudo systemctl stop k3s'"
echo "  2. Verify cluster still works: kubectl get nodes"
echo "  3. Restart first master: ssh ${SSH_USER}@${FIRST_MASTER_IP} 'sudo systemctl start k3s'"
echo "  4. Verify it rejoined: kubectl get nodes"
