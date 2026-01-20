#!/bin/bash
# Retry Terraform apply with better error handling

set -euo pipefail

cd "$(dirname "$0")"

export KUBECONFIG=~/.kube/config-homelabs

echo "=== Checking Cluster Before Terraform Apply ==="
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Cluster is not accessible. Please check cluster status first:"
  echo "   ./check-cluster-status.sh"
  exit 1
fi

echo "✅ Cluster is accessible"
echo ""

# Check if monitoring is the target
if [ "${1:-}" = "monitoring" ]; then
  echo "Applying monitoring module..."
  terraform apply -target=module.monitoring
else
  echo "Applying all changes..."
  echo "If you want to apply only monitoring, run: $0 monitoring"
  terraform apply
fi
