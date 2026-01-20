#!/bin/bash
# Comprehensive diagnostic and fix script for Kubernetes cluster connectivity
# Diagnoses the issue and fixes it automatically

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

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Kubernetes Cluster Diagnostic & Fix                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Test SSH connectivity
echo -e "${BLUE}Step 1: Testing SSH connectivity...${NC}"
if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" "echo 'SSH OK'" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} SSH connection successful"
else
  echo -e "   ${RED}✗${NC} Cannot connect to master node"
  echo ""
  echo "   Please check:"
  echo "   1. Master node is powered on and accessible"
  echo "   2. SSH is configured correctly"
  echo "   3. MASTER_IP is correct: ${MASTER_IP}"
  exit 1
fi

# Step 2: Check k3s service status
echo ""
echo -e "${BLUE}Step 2: Checking k3s service status...${NC}"
K3S_STATUS=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo systemctl is-active k3s 2>/dev/null || echo "inactive"')
if [ "$K3S_STATUS" = "active" ]; then
  echo -e "   ${GREEN}✓${NC} k3s service is running"
else
  echo -e "   ${YELLOW}⚠${NC}  k3s service is NOT running (status: $K3S_STATUS)"
  echo ""
  echo "   Attempting to start k3s..."
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo systemctl enable k3s && sudo systemctl start k3s' || true
  echo "   Waiting 10 seconds for k3s to start..."
  sleep 10
  
  K3S_STATUS=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo systemctl is-active k3s 2>/dev/null || echo "inactive"')
  if [ "$K3S_STATUS" = "active" ]; then
    echo -e "   ${GREEN}✓${NC} k3s is now running"
  else
    echo -e "   ${RED}✗${NC} k3s failed to start"
    echo ""
    echo "   Recent k3s logs:"
    ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo journalctl -u k3s -n 30 --no-pager' | tail -30
    echo ""
    echo "   Please check the logs above for errors"
    exit 1
  fi
fi

# Step 3: Test API server connectivity
echo ""
echo -e "${BLUE}Step 3: Testing API server connectivity...${NC}"
if curl -k -s --connect-timeout 5 "https://${MASTER_IP}:6443/healthz" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} API server is responding"
else
  echo -e "   ${YELLOW}⚠${NC}  API server not responding yet (may need more time)"
  echo "   Waiting 20 seconds..."
  sleep 20
  if curl -k -s --connect-timeout 5 "https://${MASTER_IP}:6443/healthz" &>/dev/null; then
    echo -e "   ${GREEN}✓${NC} API server is now responding"
  else
    echo -e "   ${RED}✗${NC} API server still not responding"
    echo "   Check k3s logs: ssh ${SSH_USER}@${MASTER_IP} 'sudo journalctl -u k3s -n 50'"
    exit 1
  fi
fi

# Step 4: Fix kubeconfig
echo ""
echo -e "${BLUE}Step 4: Fixing kubeconfig...${NC}"
KUBECONFIG_PATH=~/.kube/config-homelabs

# Backup existing kubeconfig
if [ -f "$KUBECONFIG_PATH" ]; then
  BACKUP_PATH="${KUBECONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$KUBECONFIG_PATH" "$BACKUP_PATH"
  echo "   Backed up existing kubeconfig to: $BACKUP_PATH"
fi

# Get new kubeconfig from master
echo "   Fetching kubeconfig from master node..."
mkdir -p ~/.kube

if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' 2>/dev/null | \
  sed "s/127.0.0.1/${MASTER_IP}/g" > "$KUBECONFIG_PATH"; then
  chmod 600 "$KUBECONFIG_PATH"
  echo -e "   ${GREEN}✓${NC} Kubeconfig updated: $KUBECONFIG_PATH"
else
  echo -e "   ${RED}✗${NC} Failed to fetch kubeconfig"
  exit 1
fi

# Step 5: Test kubectl
echo ""
echo -e "${BLUE}Step 5: Testing kubectl connection...${NC}"
export KUBECONFIG="$KUBECONFIG_PATH"

if kubectl cluster-info &>/dev/null 2>&1; then
  echo -e "   ${GREEN}✓${NC} kubectl is working!"
  echo ""
  echo "   Cluster info:"
  kubectl cluster-info | head -3
  echo ""
  echo "   Nodes:"
  kubectl get nodes
else
  echo -e "   ${YELLOW}⚠${NC}  kubectl test failed, trying with insecure flag..."
  if kubectl --insecure-skip-tls-verify cluster-info &>/dev/null 2>&1; then
    echo -e "   ${YELLOW}⚠${NC}  Connection works with --insecure-skip-tls-verify"
    echo "   This suggests certificate issues. The kubeconfig has been updated."
    echo "   Try: kubectl --insecure-skip-tls-verify get nodes"
  else
    echo -e "   ${RED}✗${NC} kubectl still not working"
    echo "   Check: kubectl cluster-info"
    exit 1
  fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Diagnostic & Fix Complete                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Kubeconfig location: $KUBECONFIG_PATH"
echo "To use this kubeconfig:"
echo "  export KUBECONFIG=$KUBECONFIG_PATH"
echo ""
echo "Or add to your shell profile:"
echo "  echo 'export KUBECONFIG=$KUBECONFIG_PATH' >> ~/.zshrc"
