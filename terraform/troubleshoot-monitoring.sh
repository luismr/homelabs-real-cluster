#!/bin/bash
# Troubleshoot monitoring stack installation issues

set -euo pipefail

echo "=== Checking Helm Release Status ==="
helm status kube-prometheus-stack -n monitoring || echo "Helm release not found or failed"

echo ""
echo "=== Checking Pods in Monitoring Namespace ==="
kubectl get pods -n monitoring

echo ""
echo "=== Checking Failed Pods ==="
kubectl get pods -n monitoring --field-selector=status.phase!=Running,status.phase!=Succeeded

echo ""
echo "=== Checking Events ==="
kubectl get events -n monitoring --sort-by='.lastTimestamp' | tail -20

echo ""
echo "=== Checking Prometheus Operator Pod ==="
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-operator || echo "Prometheus Operator pod not found"

echo ""
echo "=== Checking Prometheus Operator Logs (if exists) ==="
PROM_OP_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-operator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PROM_OP_POD" ]; then
  echo "Pod: $PROM_OP_POD"
  kubectl logs -n monitoring "$PROM_OP_POD" --tail=50 || echo "Could not get logs"
else
  echo "Prometheus Operator pod not found"
fi

echo ""
echo "=== Checking Helm Release History ==="
helm history kube-prometheus-stack -n monitoring || echo "No history found"

echo ""
echo "=== Checking Storage Classes ==="
kubectl get storageclass

echo ""
echo "=== Checking PVCs in Monitoring Namespace ==="
kubectl get pvc -n monitoring

echo ""
echo "=== If you need to delete and retry ==="
echo "helm uninstall kube-prometheus-stack -n monitoring"
echo "kubectl delete namespace monitoring"
echo "terraform apply -target=module.monitoring"
