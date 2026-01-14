#!/bin/bash
# Check memory usage across the cluster

set -euo pipefail

export KUBECONFIG=~/.kube/config-homelabs

echo "=== Cluster Memory Usage ==="
echo ""

echo "1. Node Memory:"
kubectl top nodes 2>/dev/null || echo "Metrics not available (metrics-server may not be running)"

echo ""
echo "2. Pod Memory Usage (sorted by memory):"
kubectl top pods -A --sort-by=memory 2>/dev/null | head -20 || echo "Metrics not available"

echo ""
echo "3. Pods by Memory Requests:"
kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU-REQ:.spec.containers[*].resources.requests.cpu,MEM-REQ:.spec.containers[*].resources.requests.memory --sort-by=.spec.containers[*].resources.requests.memory 2>/dev/null | head -20

echo ""
echo "4. Pending Pods (may be waiting for resources):"
kubectl get pods -A --field-selector=status.phase=Pending -o wide

echo ""
echo "5. Node Allocatable Resources:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-ALLOCATABLE:.status.allocatable.cpu,MEM-ALLOCATABLE:.status.allocatable.memory

echo ""
echo "6. Node Allocated Resources:"
kubectl describe nodes | grep -A 5 "Allocated resources" || echo "Could not get allocated resources"
