#!/bin/bash
# Setup NFS storage for monitoring stack
# This installs NFS provisioner and creates storage classes needed for monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source cluster hosts if available
if [ -f "${SCRIPT_DIR}/scripts/cluster-hosts.env" ]; then
  source "${SCRIPT_DIR}/scripts/cluster-hosts.env"
fi

# Set KUBECONFIG - use absolute path
KUBECONFIG_PATH="${HOME}/.kube/config-homelabs"
if [ ! -f "${KUBECONFIG_PATH}" ]; then
  echo "⚠️  Kubeconfig not found at ${KUBECONFIG_PATH}"
  echo "Please run: ./fix-kubeconfig.sh first"
  exit 1
fi
export KUBECONFIG="${KUBECONFIG_PATH}"

# Verify kubectl can connect
echo "Verifying kubectl connection..."
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ Cannot connect to cluster. Please check:"
  echo "  1. Kubeconfig is correct: ${KUBECONFIG_PATH}"
  echo "  2. Cluster is running"
  echo "  3. Run: kubectl cluster-info"
  exit 1
fi
echo "✅ kubectl connection verified"
echo ""

NFS_SERVER="${MASTER_IP:-192.168.7.200}"
SSH_USER="${SSH_USER:-ubuntu}"

echo "=== Setting up NFS Storage for Monitoring ==="
echo "NFS Server: ${NFS_SERVER}"
echo ""

# Check if NFS server is accessible
echo "Checking NFS server..."
if ! ssh -o ConnectTimeout=5 "${SSH_USER}@${NFS_SERVER}" "test -d /nfs" 2>/dev/null; then
  echo "⚠️  NFS server directories not found. Setting up NFS server first..."
  echo "Running: ${SCRIPT_DIR}/scripts/setup-nfs-server.sh"
  ssh "${SSH_USER}@${NFS_SERVER}" "bash -s -- ${NFS_SERVER}" < "${SCRIPT_DIR}/scripts/setup-nfs-server.sh" || {
    echo "❌ Failed to setup NFS server"
    exit 1
  }
fi

echo "✅ NFS server ready"
echo ""

# Deploy NFS provisioner
echo "Deploying NFS CSI provisioner..."
echo "Using KUBECONFIG: ${KUBECONFIG}"
echo ""

# Always use manual deployment to ensure correct KUBECONFIG
# (deploy-nfs-provisioner.sh might use different KUBECONFIG)
if false; then  # Disable calling deploy-nfs-provisioner.sh directly
  bash "${SCRIPT_DIR}/scripts/deploy-nfs-provisioner.sh"
else
  echo "⚠️  deploy-nfs-provisioner.sh not found, deploying manually..."
  
  # Install Helm if needed
  if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
  
  # Add NFS CSI driver Helm repository
  helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
  helm repo update
  
  # Create namespace (skip validation to avoid localhost:8080 error)
  echo "Creating nfs-system namespace..."
  kubectl create namespace nfs-system --dry-run=client -o yaml 2>/dev/null | kubectl apply --validate=false -f - || \
    kubectl create namespace nfs-system --validate=false 2>/dev/null || true
  
  # Install NFS CSI driver
  echo "Installing NFS CSI driver via Helm..."
  helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace nfs-system \
    --version v4.9.0 \
    --wait --timeout=5m \
    --kubeconfig "${KUBECONFIG}"
  
  # Wait for CSI driver to be ready
  echo "Waiting for NFS CSI driver pods to be ready..."
  kubectl wait --for=condition=ready pod -l app=csi-nfs-controller -n nfs-system --timeout=120s --kubeconfig "${KUBECONFIG}" || true
  kubectl wait --for=condition=ready pod -l app=csi-nfs-node -n nfs-system --timeout=120s --kubeconfig "${KUBECONFIG}" || true
  
  # Create StorageClasses (including nfs-loki) - skip validation
  cat <<EOF | kubectl apply --validate=false -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER}
  share: /nfs/shared
  mountPermissions: "0777"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-loki
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER}
  share: /nfs/loki
  mountPermissions: "0777"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-grafana
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER}
  share: /nfs/grafana
  mountPermissions: "0777"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-prometheus
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER}
  share: /nfs/prometheus
  mountPermissions: "0777"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-alertmanager
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS_SERVER}
  share: /nfs/alertmanager
  mountPermissions: "0777"
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
EOF
fi

echo ""
echo "=== Verifying NFS Setup ==="
echo "Storage Classes:"
kubectl get storageclass --kubeconfig "${KUBECONFIG}"

echo ""
echo "NFS CSI Driver Pods:"
kubectl get pods -n nfs-system --kubeconfig "${KUBECONFIG}"

echo ""
echo "✅ NFS storage is ready for monitoring!"
echo ""
echo "Now you can run:"
echo "  cd terraform"
echo "  terraform apply -target=module.monitoring"
