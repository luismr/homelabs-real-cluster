#!/bin/bash
# Quick fix script for k3s master - attempts to restart and fix common issues

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/../cluster-hosts.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/../cluster-hosts.env"
fi

SSH_USER=${SSH_USER:-ubuntu}
SSH_KEY=${SSH_KEY:-}
SSH_EXTRA_OPTS=${SSH_EXTRA_OPTS:-}
MASTER_IP=${MASTER_IP:-192.168.7.200}

SSH_OPTS=("-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-o" "ConnectTimeout=10")
if [ -n "${SSH_KEY}" ]; then
  SSH_OPTS+=("-i" "${SSH_KEY}")
fi
if [ -n "${SSH_EXTRA_OPTS}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARR=( ${SSH_EXTRA_OPTS} )
  SSH_OPTS+=("${EXTRA_ARR[@]}")
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  k3s Master Node Fix Script                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will attempt to fix common k3s issues on the master node"
echo "Master: ${SSH_USER}@${MASTER_IP}"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Step 1: Checking current status..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  if sudo systemctl is-active k3s &>/dev/null; then
    echo "   k3s is currently running"
  else
    echo "   k3s is NOT running"
  fi
EOF

echo ""
echo "Step 2: Enabling k3s service (if not already enabled)..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo systemctl enable k3s'

echo ""
echo "Step 3: Restarting k3s service..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo systemctl restart k3s'

echo ""
echo "Step 4: Waiting for k3s to start (30 seconds)..."
sleep 30

echo ""
echo "Step 5: Checking k3s status..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  if sudo systemctl is-active k3s &>/dev/null; then
    echo "   ✓ k3s is now running"
    echo ""
    echo "   Service status:"
    sudo systemctl status k3s --no-pager | head -10
  else
    echo "   ✗ k3s failed to start"
    echo ""
    echo "   Recent error logs:"
    sudo journalctl -u k3s -n 20 --no-pager | tail -20
    echo ""
    echo "   Please check the logs above for errors"
  fi
EOF

echo ""
echo "Step 6: Testing API server connectivity..."
sleep 5
if curl -k -s --connect-timeout 5 "https://${MASTER_IP}:6443/healthz" &>/dev/null; then
  echo "   ✓ API server is responding!"
  echo ""
  echo "   Testing kubectl connection..."
  export KUBECONFIG=~/.kube/config
  if kubectl cluster-info &>/dev/null 2>&1; then
    echo "   ✓ kubectl can connect to cluster"
    echo ""
    echo "   Cluster nodes:"
    kubectl get nodes
  else
    echo "   ⚠️  kubectl cannot connect (may need to update kubeconfig)"
    echo "   Run: ./scripts/install-k3s-master.sh (to regenerate kubeconfig)"
  fi
else
  echo "   ✗ API server is still not responding"
  echo ""
  echo "   This may take a few more minutes. Try:"
  echo "   1. Wait 2-3 more minutes"
  echo "   2. Run diagnostics: ./scripts/diagnose-master.sh"
  echo "   3. Check logs: ssh ${SSH_USER}@${MASTER_IP} 'sudo journalctl -u k3s -n 50'"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Fix Complete                                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
