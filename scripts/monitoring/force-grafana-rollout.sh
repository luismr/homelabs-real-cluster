#!/bin/bash
# Force Grafana rollout to complete by checking and fixing common issues

set -e

NAMESPACE="monitoring"
DEPLOYMENT="kube-prometheus-stack-grafana"

echo "=== Current Status ==="
kubectl get deployment $DEPLOYMENT -n $NAMESPACE
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana

echo ""
echo "=== Checking for Stuck Pods ==="
OLD_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana --field-selector=status.phase!=Running -o name 2>/dev/null || echo "")

if [ -n "$OLD_PODS" ]; then
  echo "Found old/stuck pods:"
  echo "$OLD_PODS"
  echo ""
  echo "Checking why they're stuck..."
  for pod in $OLD_PODS; do
    echo "--- Status of $pod ---"
    kubectl get $pod -n $NAMESPACE -o jsonpath='{.status.phase}{"\t"}{.status.containerStatuses[*].state}{"\n"}' || true
    kubectl describe $pod -n $NAMESPACE | grep -A 10 "Events:" || true
  done
  
  echo ""
  read -p "Force delete stuck pods? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Force deleting stuck pods..."
    for pod in $OLD_PODS; do
      kubectl delete $pod -n $NAMESPACE --force --grace-period=0 || true
    done
    echo "Pods deleted. Waiting for new pods to start..."
    sleep 5
  fi
fi

echo ""
echo "=== Checking Init Container Status ==="
NEW_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana --field-selector=status.phase=Running -o name 2>/dev/null || echo "")

if [ -z "$NEW_PODS" ]; then
  NEW_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o name | head -1 || echo "")
fi

if [ -n "$NEW_PODS" ]; then
  POD_NAME=$(echo $NEW_PODS | head -1 | cut -d/ -f2)
  echo "Checking init container for pod: $POD_NAME"
  kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].name}{"\n"}' || echo "No init containers"
  
  echo ""
  echo "Init container logs:"
  kubectl logs $POD_NAME -n $NAMESPACE -c download-dynamodb-plugin --tail=30 2>/dev/null || echo "Init container not running or completed"
fi

echo ""
echo "=== Current Rollout Status ==="
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=30s 2>&1 || echo "Rollout still in progress or failed"

echo ""
echo "=== Recommendations ==="
echo "1. If init container is stuck downloading, check network connectivity"
echo "2. If old pod won't terminate, it may have open connections - wait or force delete"
echo "3. Check PVC status: kubectl get pvc -n $NAMESPACE | grep grafana"
echo "4. Check node resources: kubectl top nodes"
echo ""
echo "To view full diagnostics, run: ./terraform/diagnose-grafana-rollout.sh"
