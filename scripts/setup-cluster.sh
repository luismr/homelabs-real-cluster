#!/bin/bash
# Automated k3s cluster setup with observability

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  k3s Cluster Setup with Observability Stack                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
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
MASTER_IP=${MASTER_IP:-192.168.7.200}
WORKER_IPS=${WORKER_IPS:-"192.168.7.201 192.168.7.202 192.168.7.203"}
WORKER_NAMES=${WORKER_NAMES:-"worker-1 worker-2 worker-3"}

# Build arrays from space-separated strings
read -r -a WORKER_IPS_ARR <<<"${WORKER_IPS}"

if [ -z "${WORKER_NAMES}" ]; then
  # Auto-generate names worker1..N
  WORKER_NAMES_ARR=()
  idx=1
  for _ in "${WORKER_IPS_ARR[@]}"; do
    WORKER_NAMES_ARR+=("worker${idx}")
    idx=$((idx + 1))
  done
else
  read -r -a WORKER_NAMES_ARR <<<"${WORKER_NAMES}"
fi

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

# Step 1: Install k3s on master
echo "[1/4] Installing k3s on master node..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'bash -s --' "${MASTER_IP}" < "${SCRIPT_DIR}/install-k3s-master.sh"

# Get the node token
echo ""
echo "[2/4] Retrieving node token from master..."
NODE_TOKEN=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo cat /var/lib/rancher/k3s/server/node-token')
echo "Node token retrieved."

# Wait a bit for master to stabilize
sleep 10

# Step 2: Install k3s on workers
echo ""
echo "[3/4] Installing k3s on worker nodes..."
for i in "${!WORKER_IPS_ARR[@]}"; do
  WORKER_IP="${WORKER_IPS_ARR[$i]}"
  WORKER_NAME="${WORKER_NAMES_ARR[$i]}"
  echo "  -> Installing on ${WORKER_NAME} (${WORKER_IP})..."
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${WORKER_IP}" "bash -s -- ${MASTER_IP} ${NODE_TOKEN}" < "${SCRIPT_DIR}/install-k3s-worker.sh" &
done

# Wait for all worker installations to complete
wait
echo "All workers installed."

# Wait for cluster to stabilize
sleep 15

# Step 3: Copy kubeconfig to local machine
echo ""
echo "[4/4] Setting up kubectl access..."
mkdir -p ~/.kube
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/${MASTER_IP}/g" > ~/.kube/config-homelabs
chmod 600 ~/.kube/config-homelabs

# Merge with existing kubeconfig or set as default
if [ -f ~/.kube/config ]; then
  echo "Kubeconfig saved to: ~/.kube/config-homelabs"
  echo "To use it, run: export KUBECONFIG=~/.kube/config-homelabs"
else
  cp ~/.kube/config-homelabs ~/.kube/config
  echo "Kubeconfig saved to: ~/.kube/config"
fi

export KUBECONFIG=~/.kube/config-homelabs

# Verify cluster
echo ""
echo "Verifying cluster..."
kubectl get nodes -o wide

# Step 4: Install observability stack
echo ""
read -p "Install observability stack (Prometheus, Grafana, Loki)? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  echo ""
  echo "Installing observability stack on master node..."
  scp "${SSH_OPTS[@]}" "${SCRIPT_DIR}/install-observability.sh" "${SSH_USER}@${MASTER_IP}:/tmp/"
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'bash /tmp/install-observability.sh'
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Cluster Setup Complete! 🎉                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Cluster Information:"
echo "  Master:   ${MASTER_IP}"
for i in "${!WORKER_IPS_ARR[@]}"; do
  idx=$((i + 1))
  echo "  Worker${idx}:  ${WORKER_IPS_ARR[$i]}"
done
echo ""
echo "To use kubectl from your machine:"
echo "  export KUBECONFIG=~/.kube/config-homelabs"
echo "  kubectl get nodes"
echo ""
echo "Access Grafana:"
echo "  http://${MASTER_IP}:30080"
echo "  Username: admin"
echo "  Password: admin"
echo ""

