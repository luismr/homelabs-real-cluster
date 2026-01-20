#!/bin/bash
# Debug monitoring stack installation issues

set -euo pipefail

export KUBECONFIG=~/.kube/config-homelabs

echo "=== Checking Monitoring Namespace ==="
kubectl get namespace monitoring || echo "Namespace doesn't exist yet"

echo ""
echo "=== Checking if Helm Release Exists ==="
helm list -n monitoring 2>/dev/null || echo "No helm releases found"

echo ""
echo "=== Checking Pods in Monitoring Namespace ==="
kubectl get pods -n monitoring 2>/dev/null || echo "No pods found"

echo ""
echo "=== Checking Failed/CrashLoopBackOff Pods ==="
kubectl get pods -n monitoring --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null || echo "No failed pods"

echo ""
echo "=== Checking Events (most recent) ==="
kubectl get events -n monitoring --sort-by='.lastTimestamp' 2>/dev/null | tail -30 || echo "No events"

echo ""
echo "=== Checking Storage Classes ==="
kubectl get storageclass

echo ""
echo "=== Checking PVCs in Monitoring Namespace ==="
kubectl get pvc -n monitoring 2>/dev/null || echo "No PVCs found"

echo ""
echo "=== Checking Node Resources ==="
kubectl top nodes 2>/dev/null || kubectl describe nodes | grep -A 5 "Allocated resources" || echo "Metrics not available"

echo ""
echo "=== Checking Prometheus Operator Pod (if exists) ==="
PROM_OP_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-operator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PROM_OP_POD" ]; then
  echo "Pod: $PROM_OP_POD"
  echo "Status:"
  kubectl get pod "$PROM_OP_POD" -n monitoring -o wide
  echo ""
  echo "Logs (last 50 lines):"
  kubectl logs -n monitoring "$PROM_OP_POD" --tail=50 || echo "Could not get logs"
else
  echo "Prometheus Operator pod not found"
fi

echo ""
echo "=== Checking Grafana Pod (if exists) ==="
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$GRAFANA_POD" ]; then
  echo "Pod: $GRAFANA_POD"
  echo "Status:"
  kubectl get pod "$GRAFANA_POD" -n monitoring -o wide
  echo ""
  echo "Events:"
  kubectl describe pod "$GRAFANA_POD" -n monitoring | grep -A 10 "Events:" || echo "No events"
fi

echo ""
echo "=== Checking Prometheus Pod (if exists) ==="
PROM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$PROM_POD" ]; then
  echo "Pod: $PROM_POD"
  echo "Status:"
  kubectl get pod "$PROM_POD" -n monitoring -o wide
  echo ""
  echo "Events:"
  kubectl describe pod "$PROM_POD" -n monitoring | grep -A 10 "Events:" || echo "No events"
fi

echo ""
echo "=== Common Issues to Check ==="
echo "1. Storage class available? Check: kubectl get storageclass"
echo "2. Node resources sufficient? Check: kubectl describe nodes"
echo "3. Image pull issues? Check pod events above"
echo "4. Network policies blocking? Check: kubectl get networkpolicies -n monitoring"
