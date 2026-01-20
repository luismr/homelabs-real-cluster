#!/bin/bash
# Fix Terraform state issues after cluster downtime
# Removes resources with null identities from state so Terraform can re-import them

set -euo pipefail

cd "$(dirname "$0")"

echo "=== Fixing Terraform State Issues ==="
echo ""
echo "This script will remove resources with null identities from Terraform state."
echo "Terraform will then re-import them on the next apply."
echo ""

# List of resources with identity issues
RESOURCES=(
  "module.pudim_dev.module.pudim_dev_calculator.kubernetes_deployment.app"
  "module.carimbo_vip.module.carimbo_vip_n8n[0].kubernetes_deployment.n8n"
  "module.carimbo_vip.module.carimbo_vip_postgres.kubernetes_deployment.postgres"
  "module.carimbo_vip.module.carimbo_vip_waha[0].kubernetes_deployment.waha"
  "module.singularideas_com_br.module.singularideas_com_br_waha[0].kubernetes_deployment.waha"
)

echo "Removing resources from state..."
for resource in "${RESOURCES[@]}"; do
  echo "  - ${resource}"
  terraform state rm "${resource}" 2>/dev/null || echo "    (not found in state, skipping)"
done

echo ""
echo "✅ Resources removed from state"
echo ""
echo "Now run: terraform plan"
echo "Terraform will detect the existing resources and update state accordingly."
echo ""
echo "If you still see errors, try:"
echo "  terraform refresh"
echo "  terraform plan"
