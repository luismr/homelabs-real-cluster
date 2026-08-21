#!/bin/bash
# Trigger descheduler once to rebalance pods across all nodes (master + workers).
# Usage: ./rebalance-now.sh [--quiet]
#   --quiet: only create the job, no before/after or wait

set -euo pipefail

export KUBECONFIG=~/.kube/config-homelabs

QUIET=false
[ "${1:-}" = "--quiet" ] && QUIET=true

# Fail fast with a clear message when the API is down (same symptom as "missing" resources).
kubectl_api_ok() {
  local out
  out=$(kubectl get ns kube-system -o name 2>&1) || {
    if echo "$out" | grep -qiE 'connection refused|dial tcp.*:6443.*refused|Unable to connect to the server|context deadline exceeded|i/o timeout|no route to host|network is unreachable'; then
      echo "❌ Kubernetes API unreachable (cannot reach the control plane). Fix that first — e.g. on the master: sudo systemctl status k3s" >&2
      echo "   Helm/kubectl error looked like: $(echo "$out" | head -1)" >&2
      return 1
    fi
    echo "$out" >&2
    return 1
  }
  return 0
}

if ! kubectl_api_ok; then
  exit 1
fi

show_distribution() {
  echo "  Pods per node:"
  kubectl get pods -A -o custom-columns=NODE:.spec.nodeName --no-headers 2>/dev/null | \
    awk '{n=$1; if(n=="") n="<pending>"; c[n]++} END{for(n in c) printf "    %-12s: %3d\n", n, c[n]}' | sort
  echo ""
  kubectl top nodes --sort-by=memory 2>/dev/null | head -6 || true
}

if ! kubectl get cronjob -n kube-system descheduler &>/dev/null; then
  echo "❌ Descheduler CronJob not found in kube-system. Install with:" >&2
  echo "   helm upgrade --install descheduler descheduler/descheduler -n kube-system --set schedule='*/30 * * * *'" >&2
  echo "   (requires a working API; see docs/REBALANCE-LOAD.md)" >&2
  exit 1
fi

if [ "$QUIET" = false ]; then
  echo "📊 Before rebalance:"
  show_distribution
  echo "🚀 Creating descheduler job..."
fi

JOB_NAME="descheduler-manual-$(date +%s)"
kubectl create job --from=cronjob/descheduler "$JOB_NAME" -n kube-system

if [ "$QUIET" = true ]; then
  echo "Job $JOB_NAME created. Check: kubectl get jobs -n kube-system -l app=descheduler"
  exit 0
fi

echo "   Job: $JOB_NAME"
echo "   Waiting for completion (up to 120s)..."
if kubectl wait --for=condition=complete --timeout=120s "job/$JOB_NAME" -n kube-system 2>/dev/null; then
  echo "   ✅ Job completed."
else
  echo "   ⚠️  Job may still be running. Check: kubectl get job $JOB_NAME -n kube-system"
fi

echo ""
echo "📊 After rebalance:"
show_distribution
