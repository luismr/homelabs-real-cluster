#!/bin/bash
# Setup NFS server on master node

set -euo pipefail

echo "=== Setting up NFS Server on Master Node ==="

# Install NFS server
echo "Installing NFS server packages..."
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server nfs-common

# Create NFS export directories
echo "Creating NFS export directories..."
sudo mkdir -p /nfs/shared
sudo mkdir -p /nfs/grafana
sudo mkdir -p /nfs/prometheus
sudo mkdir -p /nfs/loki
sudo mkdir -p /nfs/alertmanager

# Set permissions
sudo chmod -R 777 /nfs/
sudo chown -R nobody:nogroup /nfs/

# Configure NFS exports
echo "Configuring NFS exports..."
sudo tee /etc/exports > /dev/null << 'EOF'
# NFS exports for k3s cluster
/nfs/shared      192.168.7.0/24(rw,sync,no_subtree_check,no_root_squash)
/nfs/grafana     192.168.7.0/24(rw,sync,no_subtree_check,no_root_squash)
/nfs/prometheus  192.168.7.0/24(rw,sync,no_subtree_check,no_root_squash)
/nfs/loki        192.168.7.0/24(rw,sync,no_subtree_check,no_root_squash)
/nfs/alertmanager 192.168.7.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

# Export the filesystems
echo "Exporting NFS filesystems..."
sudo exportfs -ra

# Restart NFS server
echo "Restarting NFS server..."
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Show exports
echo ""
echo "=== NFS Server Setup Complete ==="
echo ""
echo "Active NFS exports:"
sudo exportfs -v
echo ""
echo "NFS server is ready at: 192.168.7.200"
echo ""
echo "Available mounts:"
echo "  /nfs/shared      - General purpose shared storage"
echo "  /nfs/grafana     - Grafana persistent storage"
echo "  /nfs/prometheus  - Prometheus persistent storage"
echo "  /nfs/loki        - Loki persistent storage"
echo "  /nfs/alertmanager - Alertmanager persistent storage"

