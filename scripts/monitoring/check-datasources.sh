#!/bin/bash
set -e

echo "=== Checking Grafana Datasource ConfigMaps ==="
kubectl get configmaps -n monitoring -l grafana_datasource=1

echo ""
echo "=== Content of kube-prometheus-stack-grafana-datasource ==="
kubectl get configmap -n monitoring kube-prometheus-stack-grafana-datasource -o yaml || echo "Not found"

echo ""
echo "=== Content of loki-datasource ==="
kubectl get configmap -n monitoring loki-datasource -o yaml || echo "Not found"
