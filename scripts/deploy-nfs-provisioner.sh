#!/bin/bash
# Deploy NFS CSI provisioner for dynamic volume provisioning

set -euo pipefail

# Set kubeconfig for k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

NFS_SERVER="192.168.7.200"

echo "=== Deploying NFS CSI Provisioner ==="

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add NFS CSI driver Helm repository
echo "Adding NFS CSI driver repository..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

# Create namespace
kubectl create namespace nfs-system --dry-run=client -o yaml | kubectl apply -f -

# Install NFS CSI driver
echo "Installing NFS CSI driver..."
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
  --namespace nfs-system \
  --version v4.9.0 \
  --wait --timeout=5m

# Wait for CSI driver to be ready
echo "Waiting for NFS CSI driver to be ready..."
kubectl wait --for=condition=ready pod -l app=csi-nfs-controller -n nfs-system --timeout=120s
kubectl wait --for=condition=ready pod -l app=csi-nfs-node -n nfs-system --timeout=120s

# Create StorageClass
echo "Creating NFS StorageClass..."
cat <<EOF | kubectl apply -f -
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
EOF

# Create additional StorageClasses for specific services
echo "Creating service-specific StorageClasses..."

cat <<EOF | kubectl apply -f -
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

echo ""
echo "=== NFS Provisioner Deployed Successfully ==="
echo ""
echo "Available StorageClasses:"
kubectl get storageclass
echo ""
echo "NFS CSI Driver Pods:"
kubectl get pods -n nfs-system
echo ""
echo "You can now create PersistentVolumeClaims with these StorageClasses:"
echo "  - nfs-client (default) - General purpose"
echo "  - nfs-grafana          - For Grafana"
echo "  - nfs-prometheus       - For Prometheus"
echo "  - nfs-loki             - For Loki"
echo "  - nfs-alertmanager     - For Alertmanager"

