#!/bin/bash
# Terraform helper script for managing Kubernetes deployments

set -euo pipefail

TERRAFORM_DIR="/Volumes/MacOS Storage/Work/homelabs/terraform"
cd "$TERRAFORM_DIR"

function show_help() {
  cat << EOF
╔════════════════════════════════════════════════════════════════╗
║  Terraform Helper - Kubernetes Deployments                     ║
╚════════════════════════════════════════════════════════════════╝

Usage: $0 <command>

Commands:
  init       Initialize Terraform
  plan       Show planned changes
  apply      Apply changes to cluster
  destroy    Destroy all managed resources
  output     Show outputs
  status     Show deployment status
  refresh    Refresh state from cluster
  
  Sites Management:
  update-content <site> <file>  Upload content to site
  list-sites                     List all deployed sites
  logs <site>                    Show logs for a site
  
Examples:
  $0 init
  $0 plan
  $0 apply
  $0 status
  $0 update-content pudim-dev ./my-site/index.html
  $0 logs pudim-dev

EOF
}

function check_terraform() {
  if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
  fi
}

function check_kubectl() {
  if ! kubectl version --client &> /dev/null; then
    echo "Error: kubectl is not available"
    exit 1
  fi
}

function terraform_init() {
  echo "Initializing Terraform..."
  terraform init
}

function terraform_plan() {
  echo "Planning Terraform changes..."
  terraform plan
}

function terraform_apply() {
  echo "Applying Terraform changes..."
  terraform apply
}

function terraform_destroy() {
  echo "⚠️  WARNING: This will destroy all managed resources!"
  read -p "Are you sure? (yes/no): " confirm
  if [ "$confirm" == "yes" ]; then
    terraform destroy
  else
    echo "Cancelled."
  fi
}

function terraform_output() {
  terraform output
}

function show_status() {
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  Deployment Status                                             ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  
  export KUBECONFIG=~/.kube/config-homelabs
  
  echo "=== Namespace ==="
  kubectl get namespace static-sites 2>/dev/null || echo "Not deployed"
  
  echo ""
  echo "=== Sites ==="
  kubectl get deployments -n static-sites 2>/dev/null || echo "No deployments"
  
  echo ""
  echo "=== Services ==="
  kubectl get services -n static-sites 2>/dev/null || echo "No services"
  
  echo ""
  echo "=== PVCs ==="
  kubectl get pvc -n static-sites 2>/dev/null || echo "No PVCs"
  
  echo ""
  echo "=== Cloudflare Tunnel ==="
  kubectl get deployment cloudflare-tunnel -n static-sites 2>/dev/null || echo "Not deployed"
}

function list_sites() {
  export KUBECONFIG=~/.kube/config-homelabs
  echo "=== Deployed Sites ==="
  kubectl get services -n static-sites -o custom-columns=NAME:.metadata.name,DOMAIN:.metadata.annotations.'cloudflare-tunnel/hostname' 2>/dev/null || echo "No sites deployed"
}

function update_content() {
  local site=$1
  local file=$2
  
  if [ ! -f "$file" ]; then
    echo "Error: File not found: $file"
    exit 1
  fi
  
  export KUBECONFIG=~/.kube/config-homelabs
  
  echo "Updating content for $site..."
  
  # Get pod name
  local pod=$(kubectl get pods -n static-sites -l app=$site -o jsonpath='{.items[0].metadata.name}')
  
  if [ -z "$pod" ]; then
    echo "Error: No pod found for site: $site"
    exit 1
  fi
  
  # Copy file to pod
  kubectl cp "$file" static-sites/$pod:/usr/share/nginx/html/$(basename "$file")
  
  echo "✓ Content updated successfully"
}

function show_logs() {
  local site=$1
  export KUBECONFIG=~/.kube/config-homelabs
  kubectl logs -n static-sites -l app=$site --tail=50 -f
}

function terraform_refresh() {
  echo "Refreshing Terraform state..."
  terraform refresh
}

# Main
check_terraform
check_kubectl

case "${1:-help}" in
  init)
    terraform_init
    ;;
  plan)
    terraform_plan
    ;;
  apply)
    terraform_apply
    ;;
  destroy)
    terraform_destroy
    ;;
  output)
    terraform_output
    ;;
  status)
    show_status
    ;;
  refresh)
    terraform_refresh
    ;;
  list-sites)
    list_sites
    ;;
  update-content)
    if [ $# -lt 3 ]; then
      echo "Usage: $0 update-content <site> <file>"
      exit 1
    fi
    update_content "$2" "$3"
    ;;
  logs)
    if [ $# -lt 2 ]; then
      echo "Usage: $0 logs <site>"
      exit 1
    fi
    show_logs "$2"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac

