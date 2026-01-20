#!/bin/bash
# Fix Terraform state for moved ServiceMonitor resources
# Since ServiceMonitor is now disabled (count=0), remove them from state

set -euo pipefail

cd "$(dirname "$0")"

echo "Removing ServiceMonitor resources from Terraform state..."
echo "These resources are now disabled (enable_servicemonitor = false)"
echo ""

# Remove ServiceMonitor resources from state
terraform state rm 'module.carimbo_vip.module.carimbo_vip_n8n[0].kubernetes_manifest.n8n_servicemonitor' || true
terraform state rm 'module.carimbo_vip.module.carimbo_vip_postgres.kubernetes_manifest.postgres_servicemonitor' || true
terraform state rm 'module.carimbo_vip.module.carimbo_vip_redis.kubernetes_manifest.redis_servicemonitor' || true
terraform state rm 'module.pudim_dev.module.pudim_dev_redis.kubernetes_manifest.redis_servicemonitor' || true

echo ""
echo "✅ ServiceMonitor resources removed from state"
echo ""
echo "Now you can run:"
echo "  terraform apply -target=module.monitoring"
echo "or"
echo "  terraform apply  # to apply everything"
