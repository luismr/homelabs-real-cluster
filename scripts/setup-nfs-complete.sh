#!/bin/bash
# Complete NFS setup - server, clients, and provisioner

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  NFS Shared Storage Setup                                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

MASTER_IP="192.168.7.200"
WORKER_IPS=("192.168.7.201" "192.168.7.202" "192.168.7.203")

# Step 1: Setup NFS server on master
echo "[1/3] Setting up NFS server on master node..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${MASTER_IP} 'bash -s' < scripts/setup-nfs-server.sh

# Wait for NFS to be ready
sleep 5

# Step 2: Setup NFS clients on workers
echo ""
echo "[2/3] Setting up NFS clients on worker nodes..."
for WORKER_IP in "${WORKER_IPS[@]}"; do
  echo "  -> Setting up $WORKER_IP..."
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${WORKER_IP} "bash -s -- ${MASTER_IP}" < scripts/setup-nfs-clients.sh &
done

# Wait for all workers
wait
echo "All NFS clients configured."

# Wait for cluster to settle
sleep 5

# Step 3: Deploy NFS CSI provisioner
echo ""
echo "[3/3] Deploying NFS CSI provisioner to Kubernetes..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scripts/deploy-nfs-provisioner.sh root@${MASTER_IP}:/tmp/
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${MASTER_IP} 'bash /tmp/deploy-nfs-provisioner.sh'

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  NFS Setup Complete! 🎉                                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 NFS Server: 192.168.7.200"
echo ""
echo "📦 Available Storage:"
echo "   /nfs/shared      - General purpose (10GB+)"
echo "   /nfs/grafana     - Reserved for Grafana"
echo "   /nfs/prometheus  - Reserved for Prometheus"
echo "   /nfs/loki        - Reserved for Loki"
echo "   /nfs/alertmanager - Reserved for Alertmanager"
echo ""
echo "🔧 Available StorageClasses:"
echo "   nfs-client       - Default, uses /nfs/shared"
echo "   nfs-grafana      - Uses /nfs/grafana"
echo "   nfs-prometheus   - Uses /nfs/prometheus"
echo "   nfs-loki         - Uses /nfs/loki"
echo "   nfs-alertmanager - Uses /nfs/alertmanager"
echo ""
echo "📝 Verify setup:"
echo "   kubectl get storageclass"
echo "   kubectl get pods -n nfs-system"
echo ""
echo "📖 Documentation: docs/NFS-STORAGE-GUIDE.md"
echo ""

