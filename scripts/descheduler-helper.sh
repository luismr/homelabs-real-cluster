#!/bin/bash
# Descheduler helper script - Monitor and manually trigger pod rebalancing

set -euo pipefail

export KUBECONFIG=~/.kube/config-homelabs

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Kubernetes Descheduler Helper                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if descheduler is installed
if ! kubectl get cronjob -n kube-system descheduler &>/dev/null; then
    echo "❌ Descheduler is not installed"
    echo ""
    echo "Install it with:"
    echo "  helm install descheduler descheduler/descheduler --namespace kube-system"
    exit 1
fi

echo "✅ Descheduler is installed"
echo ""

# Show current pod distribution
echo "📊 Current Pod Distribution:"
echo "─────────────────────────────────────────────────────────────────"
kubectl get pods -A -o wide --no-headers 2>/dev/null | awk '{print $NF}' | sort | uniq -c | awk '{printf "  %-15s: %3d pods\n", $2, $1}' || echo "  Unable to get pod distribution"
echo ""

# Show node resource usage
echo "💻 Node Resource Usage:"
echo "─────────────────────────────────────────────────────────────────"
kubectl top nodes 2>/dev/null | tail -n +2 | awk '{printf "  %-15s: CPU %5s (%3s%%), Memory %6s (%3s%%)\n", $1, $2, $3, $4, $5}' || echo "  Metrics server not available"
echo ""

# Show descheduler status
echo "⏰ Descheduler Schedule:"
echo "─────────────────────────────────────────────────────────────────"
kubectl get cronjob -n kube-system descheduler -o jsonpath='{.spec.schedule}' 2>/dev/null | xargs -I {} echo "  Runs every: {}" || echo "  Unable to get schedule"
echo ""

# Show recent descheduler jobs
echo "📋 Recent Descheduler Jobs:"
echo "─────────────────────────────────────────────────────────────────"
kubectl get jobs -n kube-system -l app=descheduler --sort-by=.metadata.creationTimestamp | tail -5 || echo "  No jobs found"
echo ""

# Show descheduler policy
echo "⚙️  Descheduler Policy:"
echo "─────────────────────────────────────────────────────────────────"
kubectl get configmap -n kube-system descheduler -o jsonpath='{.data.policy\.yaml}' 2>/dev/null | grep -A 5 "LowNodeUtilization:" | head -6 || echo "  Unable to get policy"
echo ""

# Menu
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Actions                                                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Trigger descheduler now (create manual job)"
echo "2. View descheduler logs"
echo "3. View descheduler policy"
echo "4. Check pod distribution after rebalancing"
echo "5. Exit"
echo ""

read -p "Select an option [1-5]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Triggering descheduler manually..."
        JOB_NAME="descheduler-manual-$(date +%s)"
        kubectl create job --from=cronjob/descheduler "$JOB_NAME" -n kube-system
        echo "✅ Created job: $JOB_NAME"
        echo ""
        echo "Waiting for job to complete (this may take a minute)..."
        kubectl wait --for=condition=complete --timeout=120s job/$JOB_NAME -n kube-system 2>/dev/null || echo "⚠️  Job may still be running"
        echo ""
        echo "📋 Job status:"
        kubectl get job $JOB_NAME -n kube-system
        echo ""
        echo "📝 Job logs:"
        kubectl logs -n kube-system -l job-name=$JOB_NAME --tail=50 || echo "  Logs not available yet"
        ;;
    2)
        echo ""
        echo "📝 Descheduler Logs:"
        echo "─────────────────────────────────────────────────────────────────"
        LATEST_JOB=$(kubectl get jobs -n kube-system -l app=descheduler --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null)
        if [ -n "$LATEST_JOB" ]; then
            kubectl logs -n kube-system -l job-name=$LATEST_JOB --tail=100 || echo "  No logs available"
        else
            echo "  No jobs found"
        fi
        ;;
    3)
        echo ""
        echo "⚙️  Descheduler Policy:"
        echo "─────────────────────────────────────────────────────────────────"
        kubectl get configmap -n kube-system descheduler -o yaml
        ;;
    4)
        echo ""
        echo "📊 Pod Distribution:"
        echo "─────────────────────────────────────────────────────────────────"
        kubectl get pods -A -o wide --no-headers | awk '{print $NF}' | sort | uniq -c | awk '{printf "  %-15s: %3d pods\n", $2, $1}'
        echo ""
        echo "💻 Node Resource Usage:"
        echo "─────────────────────────────────────────────────────────────────"
        kubectl top nodes 2>/dev/null || echo "  Metrics server not available"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
