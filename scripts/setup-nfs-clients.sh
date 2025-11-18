#!/bin/bash
# Setup NFS clients on worker nodes

set -euo pipefail

NFS_SERVER=${1:-192.168.7.200}

echo "=== Setting up NFS Client ==="
echo "NFS Server: $NFS_SERVER"
echo "Node: $(hostname)"

# Install NFS client
echo "Installing NFS client packages..."
apt-get update -y
apt-get install -y nfs-common

# Create mount point
echo "Creating mount points..."
mkdir -p /mnt/nfs-shared

# Test NFS connectivity
echo "Testing NFS connectivity..."
showmount -e $NFS_SERVER || {
    echo "ERROR: Cannot reach NFS server at $NFS_SERVER"
    exit 1
}

echo ""
echo "=== NFS Client Setup Complete ==="
echo "Available NFS exports from $NFS_SERVER:"
showmount -e $NFS_SERVER

