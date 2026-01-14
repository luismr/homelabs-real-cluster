#!/bin/bash
# Import existing Kubernetes resources back into Terraform state

set -euo pipefail

cd "$(dirname "$0")"

export KUBECONFIG=~/.kube/config-homelabs

echo "=== Importing Existing Resources into Terraform State ==="
echo ""

# Resources to import (format: terraform_resource_address namespace/name)
RESOURCES=(
  "module.pudim_dev.module.pudim_dev_calculator.kubernetes_deployment.app pudim-dev/calculator"
  "module.carimbo_vip.module.carimbo_vip_n8n[0].kubernetes_deployment.n8n carimbo-vip/n8n"
  "module.carimbo_vip.module.carimbo_vip_postgres.kubernetes_deployment.postgres carimbo-vip/postgres"
  "module.carimbo_vip.module.carimbo_vip_waha[0].kubernetes_deployment.waha carimbo-vip/waha"
  "module.singularideas_com_br.module.singularideas_com_br_waha[0].kubernetes_deployment.waha singularideas-com-br/waha"
)

echo "Importing resources..."
for resource_info in "${RESOURCES[@]}"; do
  read -r terraform_address k8s_address <<< "${resource_info}"
  namespace=$(echo "${k8s_address}" | cut -d'/' -f1)
  name=$(echo "${k8s_address}" | cut -d'/' -f2)
  
  echo "  - ${terraform_address}"
  echo "    Importing: ${namespace}/${name}"
  
  # Check if resource exists in Kubernetes
  if kubectl get deployment "${name}" -n "${namespace}" &>/dev/null; then
    # Import using terraform import
    if terraform import "${terraform_address}" "${k8s_address}" 2>&1; then
      echo "    ✅ Imported successfully"
    else
      echo "    ⚠️  Import failed (may already be in state)"
    fi
  else
    echo "    ❌ Resource not found in Kubernetes: ${namespace}/${name}"
  fi
  echo ""
done

echo "✅ Import complete!"
echo ""
echo "Now run: terraform plan"
echo "Terraform should now recognize the existing resources."
