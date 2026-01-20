#!/bin/bash
# Check Kubernetes cluster status

set -euo pipefail

export KUBECONFIG=~/.kube/config-homelabs

echo "=== Checking Kubernetes Cluster Status ==="
echo ""

# Check if we can reach the API server
echo "1. Testing API server connection..."
if kubectl cluster-info &>/dev/null; then
  echo "✅ API server is accessible"
  kubectl cluster-info | head -3
else
  echo "❌ Cannot connect to API server"
  echo ""
  echo "Checking if master node is reachable..."
  if ping -c 1 -W 2 192.168.7.200 &>/dev/null; then
    echo "✅ Master node (192.168.7.200) is reachable"
    echo ""
    echo "Checking k3s service on master..."
    ssh ubuntu@192.168.7.200 'sudo systemctl status k3s --no-pager | head -10' 2>/dev/null || echo "Cannot SSH to master"
  else
    echo "❌ Master node (192.168.7.200) is not reachable"
  fi
  exit 1
fi

echo ""
echo "2. Checking nodes..."
kubectl get nodes

echo ""
echo "3. Checking system pods..."
kubectl get pods -n kube-system | head -10

echo ""
echo "4. Checking if API server is healthy..."
kubectl get --raw /healthz && echo "✅ API server is healthy"

echo ""
echo "=== Cluster Status Summary ==="
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
echo "Total nodes: ${NODE_COUNT}"
echo "Ready nodes: ${READY_NODES}"

if [ "${READY_NODES}" -eq 0 ]; then
  echo "⚠️  No nodes are ready!"
fi
