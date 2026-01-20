# Scripts Directory

This directory contains all the utility scripts for managing the Kubernetes cluster and infrastructure, organized into logical categories.

## 📁 Directory Structure

```
scripts/
├── README.md                    # This documentation
├── cluster-hosts.env           # Cluster configuration file
├── cluster-management/         # Core cluster operations
├── diagnostics/               # Troubleshooting and health checks
├── infrastructure/            # Initial setup and configuration
├── monitoring/               # Observability stack management
├── storage/                  # NFS and persistent storage
└── terraform-helpers/        # Infrastructure as code helpers
```

## 📋 Table of Contents

- [Cluster Management](#-cluster-management)
- [Diagnostics & Troubleshooting](#-diagnostics--troubleshooting)
- [Infrastructure Setup](#️-infrastructure-setup)
- [Terraform Helpers](#-terraform-helpers)
- [Monitoring & Observability](#-monitoring--observability)
- [Network & Storage](#️-network--storage)
- [Usage Examples](#-usage-examples)

## 🚀 Cluster Management

**Location**: `cluster-management/`

### Core Cluster Scripts
- **`setup-cluster.sh`** - Complete cluster setup automation
- **`verify-cluster.sh`** - Comprehensive cluster health verification
- **`ssh-nodes.sh`** - SSH into cluster nodes with host resolution

### Node Management
- **`install-k3s-master.sh`** - Install k3s master node
- **`install-k3s-worker.sh`** - Install k3s worker node
- **`convert-worker-to-master.sh`** - Convert worker to master node
- **`convert-master-to-ha.sh`** - Convert single master to HA setup
- **`convert-all-to-masters.sh`** - Convert all workers to masters (HA cluster)

### Usage Examples
```bash
# Complete cluster setup
./cluster-management/setup-cluster.sh

# Verify everything is working
./cluster-management/verify-cluster.sh

# SSH to a specific node
./cluster-management/ssh-nodes.sh master
```

## 🔍 Diagnostics & Troubleshooting

**Location**: `diagnostics/`

### Cluster Diagnostics
- **`diagnose-and-fix-cluster.sh`** - Comprehensive cluster diagnosis and auto-fix
- **`diagnose-master.sh`** - Detailed master node diagnostics
- **`check-cluster-status.sh`** - Quick cluster status check
- **`fix-k3s-master.sh`** - Fix common k3s master issues
- **`check-memory-usage.sh`** - Monitor cluster memory usage

### Application Diagnostics
- **`diagnose-luismachadoreis-dev.sh`** - Diagnose luismachadoreis.dev domain issues
- **`quick-check-luismachadoreis.sh`** - Quick status check for luismachadoreis.dev
- **`diagnose-grafana-rollout.sh`** - Diagnose slow Grafana deployments

### Usage Examples
```bash
# Diagnose and auto-fix cluster issues
./diagnostics/diagnose-and-fix-cluster.sh

# Check specific domain issues
./diagnostics/diagnose-luismachadoreis-dev.sh

# Fix master node problems
./diagnostics/fix-k3s-master.sh
```

## 🏗️ Infrastructure Setup

**Location**: `infrastructure/`

### Initial Setup
- **`set-env-vars.sh`** - Set environment variables for cluster operations
- **`terraform-helper.sh`** - Terraform operations helper
- **`descheduler-helper.sh`** - Kubernetes descheduler management

### Usage Examples
```bash
# Set up environment variables
./infrastructure/set-env-vars.sh

# Use terraform helper for operations
./infrastructure/terraform-helper.sh
```

## 🔧 Terraform Helpers

**Location**: `terraform-helpers/`

### State Management
- **`fix-terraform-state.sh`** - Fix Terraform state issues
- **`fix-servicemonitor-state.sh`** - Fix ServiceMonitor Terraform state
- **`import-existing-resources.sh`** - Import existing resources to Terraform

### Operations
- **`retry-terraform-apply.sh`** - Retry Terraform apply with error handling
- **`retry-terraform-plan.sh`** - Retry Terraform plan for transient issues
- **`fix-kubeconfig.sh`** - Regenerate kubeconfig from master node

### Usage Examples
```bash
# Retry failed terraform apply
./terraform-helpers/retry-terraform-apply.sh

# Fix terraform state issues
./terraform-helpers/fix-terraform-state.sh

# Fix kubeconfig issues
./terraform-helpers/fix-kubeconfig.sh
```

## 📊 Monitoring & Observability

**Location**: `monitoring/`

### Setup
- **`install-observability.sh`** - Install complete observability stack
- **`install-monitoring-first.sh`** - Install monitoring components first
- **`debug-monitoring-install.sh`** - Debug monitoring installation issues

### Management
- **`troubleshoot-monitoring.sh`** - Troubleshoot monitoring stack issues
- **`force-grafana-rollout.sh`** - Force Grafana pod rollout
- **`check-helm.sh`** - Check Helm deployments status

### Usage Examples
```bash
# Install complete observability stack
./monitoring/install-observability.sh

# Force Grafana rollout if stuck
./monitoring/force-grafana-rollout.sh

# Check Helm deployments
./monitoring/check-helm.sh
```

## 🗄️ Network & Storage

**Location**: `storage/`

### NFS Storage
- **`setup-nfs-server.sh`** - Set up NFS server
- **`setup-nfs-clients.sh`** - Configure NFS clients
- **`setup-nfs-complete.sh`** - Complete NFS setup (server + clients)
- **`deploy-nfs-provisioner.sh`** - Deploy NFS CSI provisioner
- **`setup-nfs-for-monitoring.sh`** - Set up NFS specifically for monitoring

### Usage Examples
```bash
# Complete NFS setup
./storage/setup-nfs-complete.sh

# Set up NFS for monitoring
./storage/setup-nfs-for-monitoring.sh

# Deploy NFS provisioner
./storage/deploy-nfs-provisioner.sh
```

## 💡 Usage Examples

### Quick Start
```bash
# Complete cluster setup
./cluster-management/setup-cluster.sh

# Verify everything is working
./cluster-management/verify-cluster.sh

# Check cluster status
./diagnostics/check-cluster-status.sh
```

### Troubleshooting Workflow
```bash
# 1. Diagnose and auto-fix cluster issues
./diagnostics/diagnose-and-fix-cluster.sh

# 2. Check specific domain issues
./diagnostics/diagnose-luismachadoreis-dev.sh

# 3. Fix master node problems if needed
./diagnostics/fix-k3s-master.sh

# 4. Check memory usage
./diagnostics/check-memory-usage.sh
```

### Maintenance Tasks
```bash
# Force Grafana rollout if stuck
./monitoring/force-grafana-rollout.sh

# Fix kubeconfig issues
./terraform-helpers/fix-kubeconfig.sh

# Retry failed terraform operations
./terraform-helpers/retry-terraform-apply.sh
```

## 🔑 Prerequisites

Most scripts require:
- **SSH access** to cluster nodes (configured in `cluster-hosts.env`)
- **kubectl** configured with cluster access
- **Terraform** for infrastructure scripts
- **Helm** for monitoring scripts

## ⚙️ Configuration

Edit `cluster-hosts.env` to configure:
- SSH user and key
- Master and worker node IPs
- Node names and additional SSH options

## 🚨 Important Notes

- **Always backup** before running destructive operations
- **Test scripts** in a development environment first
- **Check permissions** - most scripts need to be executable (`chmod +x`)
- **Review logs** after running diagnostic scripts
- **Confirm changes** before applying Terraform modifications

### ⚙️ Execution Context

Scripts can be run from their category directories or from the project root:

```bash
# From category directory (recommended)
cd scripts/cluster-management/
./setup-cluster.sh

# From project root
./scripts/cluster-management/setup-cluster.sh
```

All scripts automatically locate the `cluster-hosts.env` configuration file using relative paths.

## 📝 Script Categories Summary

| Category | Location | Count | Purpose |
|----------|----------|-------|---------|
| **🚀 Cluster Management** | `cluster-management/` | 8 | Core cluster operations |
| **🔍 Diagnostics** | `diagnostics/` | 8 | Troubleshooting and health checks |
| **🏗️ Infrastructure** | `infrastructure/` | 3 | Initial setup and configuration |
| **🔧 Terraform** | `terraform-helpers/` | 6 | Infrastructure as code helpers |
| **📊 Monitoring** | `monitoring/` | 6 | Observability stack management |
| **🗄️ Storage** | `storage/` | 5 | NFS and persistent storage |

**Total: 36 scripts** organized in 6 categories for comprehensive cluster management! 🎯

## 🔗 Navigation

- **[← Back to Main README](../README.md)**
- **[Terraform Documentation](../terraform/README.md)**
- **[Domains Documentation](../terraform/domains/README.md)**