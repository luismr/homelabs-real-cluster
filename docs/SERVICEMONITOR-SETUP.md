# ServiceMonitor Setup Guide

## Issue

Terraform errors occur when trying to create ServiceMonitor resources before the Prometheus Operator CRD is installed:

```
Error: failed to determine resource GVK: no matches for kind "ServiceMonitor" in group "monitoring.coreos.com"
```

## Solution

ServiceMonitor resources are now **conditional** and **disabled by default**. They will only be created when:
1. Monitoring stack (Prometheus Operator) is installed
2. `enable_servicemonitor = true` is set

## Steps to Enable ServiceMonitor

### Step 1: Install Monitoring Stack First

```bash
cd terraform

# Install monitoring stack (creates ServiceMonitor CRD)
terraform apply -target=module.monitoring

# Wait for Prometheus Operator to be ready (~2-3 minutes)
kubectl wait --for=condition=Established crd/servicemonitors.monitoring.coreos.com --timeout=300s
```

### Step 2: Enable ServiceMonitor in Domain Modules

Edit the domain module files (e.g., `domains/carimbo-vip/main.tf`) and change:

```hcl
enable_servicemonitor = false  # Change to true
```

For:
- `module.carimbo_vip_redis` 
- `module.carimbo_vip_n8n`
- `module.carimbo_vip_postgres`
- `module.pudim_dev_redis`

### Step 3: Apply Changes

```bash
terraform apply
```

## Current Status

ServiceMonitor resources are **disabled by default** in:
- ✅ Redis modules (carimbo-vip, pudim-dev)
- ✅ n8n modules (carimbo-vip)
- ✅ PostgreSQL modules (carimbo-vip)

They can be enabled after monitoring is installed.

## Quick Enable Script

After monitoring is installed, run:

```bash
# Enable ServiceMonitor in all modules
cd terraform
sed -i '' 's/enable_servicemonitor = false/enable_servicemonitor = true/g' domains/carimbo-vip/main.tf
sed -i '' 's/enable_servicemonitor = false/enable_servicemonitor = true/g' domains/pudim-dev/main.tf

# Apply changes
terraform apply
```

## Verify ServiceMonitor Resources

```bash
# Check if ServiceMonitor CRD exists
kubectl get crd servicemonitors.monitoring.coreos.com

# List ServiceMonitor resources
kubectl get servicemonitor -A

# Check if Prometheus is discovering them
kubectl get servicemonitor -n carimbo-vip
```
