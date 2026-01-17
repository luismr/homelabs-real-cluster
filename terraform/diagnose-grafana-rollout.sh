#!/bin/bash
# Diagnostic script for Grafana deployment rollout issues

set -e

NAMESPACE="monitoring"
DEPLOYMENT="kube-prometheus-stack-grafana"

echo "=== Grafana Deployment Status ==="
kubectl get deployment $DEPLOYMENT -n $NAMESPACE

echo ""
echo "=== Grafana Pods Status ==="
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o wide

echo ""
echo "=== Pod Events (checking all Grafana pods) ==="
for pod in $(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o name); do
  echo "--- Events for $pod ---"
  kubectl describe $pod -n $NAMESPACE | grep -A 20 "Events:"
  echo ""
done

echo ""
echo "=== Checking for Init Containers ==="
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.initContainerStatuses[*].name}{"\t"}{.status.initContainerStatuses[*].state}{"\n"}{end}'

echo ""
echo "=== Checking Pod Logs (Init Containers) ==="
for pod in $(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o name | head -1); do
  echo "--- Init container logs for $pod ---"
  kubectl logs $pod -n $NAMESPACE --all-containers=true --prefix=true | tail -50 || echo "No logs available"
  echo ""
done

echo ""
echo "=== Checking Resource Usage ==="
kubectl top pods -n $NAMESPACE -l app.kubernetes.io/name=grafana 2>/dev/null || echo "Metrics not available"

echo ""
echo "=== Checking PVC Status ==="
kubectl get pvc -n $NAMESPACE | grep grafana

echo ""
echo "=== Checking for Stuck Pods ==="
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.containerStatuses[*].state}{"\n"}{end}'

echo ""
echo "=== Deployment Rollout History ==="
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE

echo ""
echo "=== Checking Termination Grace Period ==="
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}{"\n"}' || echo "Using default (30s)"
