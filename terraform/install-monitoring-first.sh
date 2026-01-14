#!/bin/bash
# Install monitoring stack first to ensure ServiceMonitor CRD exists
# This fixes Terraform errors about missing ServiceMonitor CRD

set -euo pipefail

echo "Installing monitoring stack first..."
echo "This ensures Prometheus Operator and ServiceMonitor CRD are available"
echo ""

cd "$(dirname "$0")"

# Install monitoring module first
terraform apply -target=module.monitoring -auto-approve

echo ""
echo "Waiting for Prometheus Operator to be ready..."
sleep 30

# Check if ServiceMonitor CRD exists
echo "Checking for ServiceMonitor CRD..."
kubectl get crd servicemonitors.monitoring.coreos.com || {
  echo "⚠️  ServiceMonitor CRD not found yet, waiting..."
  sleep 30
  kubectl get crd servicemonitors.monitoring.coreos.com || {
    echo "❌ ServiceMonitor CRD still not found. Check Prometheus Operator installation."
    exit 1
  }
}

echo "✅ ServiceMonitor CRD is available!"
echo ""
echo "Now you can run: terraform apply"
echo "ServiceMonitor resources will be created successfully."
