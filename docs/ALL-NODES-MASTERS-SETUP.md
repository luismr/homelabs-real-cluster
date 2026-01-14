# Convert All Nodes to Control Plane (All Masters)

This guide explains how to convert all nodes in your k3s cluster to control plane nodes, making every node capable of acting as a master.

## Overview

After conversion, all nodes will:
- ✅ Run control plane components (API server, etcd, scheduler, controller-manager)
- ✅ Be able to handle API requests
- ✅ Provide high availability - if one master fails, others continue
- ✅ Automatically rejoin when a failed master returns

## Architecture

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Master Node 1  │  │  Master Node 2  │  │  Master Node 3  │  │  Master Node 4  │
│  192.168.7.200  │  │  192.168.7.201  │  │  192.168.7.202  │  │  192.168.7.203  │
│  (Control Plane)│  │  (Control Plane)│  │  (Control Plane)│  │  (Control Plane)│
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
         │                    │                    │                    │
         └────────────────────┴────────────────────┴────────────────────┘
                               │
                        etcd Cluster
```

## Quick Setup (Automated)

### Step 1: Run the Conversion Script

```bash
cd ~/cluster
./scripts/convert-all-to-masters.sh
```

The script will:
1. Convert the first master to HA mode (if not already)
2. Convert each worker node to a control plane node
3. Verify all nodes are now masters

**Expected output:**
```
╔════════════════════════════════════════════════════════════════╗
║  Convert All Nodes to Control Plane (All Masters)           ║
╚════════════════════════════════════════════════════════════════╝

[1/3] Converting first master to HA mode...
[2/3] Converting worker nodes to control plane...
[3/3] Verifying cluster...

All nodes are now control plane nodes (masters):
  - 192.168.7.200 (first master)
  - 192.168.7.201 (converted to master)
  - 192.168.7.202 (converted to master)
  - 192.168.7.203 (converted to master)
```

## Manual Setup

### Step 1: Convert First Master to HA Mode

```bash
# SSH to first master
ssh ubuntu@192.168.7.200

# Run conversion script
bash scripts/convert-master-to-ha.sh 192.168.7.200

# Save the K3S_TOKEN that's displayed
```

### Step 2: Convert Each Worker to Master

For each worker node:

```bash
# Example: Convert worker-1 (192.168.7.201)
ssh ubuntu@192.168.7.201
bash scripts/convert-worker-to-master.sh 192.168.7.201 192.168.7.200 <K3S_TOKEN>

# Repeat for other workers
ssh ubuntu@192.168.7.202
bash scripts/convert-worker-to-master.sh 192.168.7.202 192.168.7.200 <K3S_TOKEN>

ssh ubuntu@192.168.7.203
bash scripts/convert-worker-to-master.sh 192.168.7.203 192.168.7.200 <K3S_TOKEN>
```

## Verify Conversion

After conversion, verify all nodes are control plane:

```bash
kubectl get nodes -o wide
```

You should see all nodes with `control-plane,etcd,master` roles:

```
NAME      STATUS   ROLES                       AGE   VERSION
master    Ready    control-plane,etcd,master   10m   v1.33.5+k3s1
worker-1  Ready    control-plane,etcd,master   5m    v1.33.5+k3s1
worker-2  Ready    control-plane,etcd,master   5m    v1.33.5+k3s1
worker-3  Ready    control-plane,etcd,master   5m    v1.33.5+k3s1
```

## Testing High Availability

### Test 1: Stop One Master

```bash
# Stop k3s on first master
ssh ubuntu@192.168.7.200 'sudo systemctl stop k3s'

# Verify cluster still works (use another master's kubeconfig)
kubectl get nodes
kubectl get pods -A

# Cluster should continue operating normally
```

### Test 2: Stop Multiple Masters

```bash
# Stop 2 masters
ssh ubuntu@192.168.7.200 'sudo systemctl stop k3s'
ssh ubuntu@192.168.7.201 'sudo systemctl stop k3s'

# With 4 masters, cluster should still work (2 remaining)
kubectl get nodes
```

### Test 3: Restart Masters

```bash
# Restart stopped masters
ssh ubuntu@192.168.7.200 'sudo systemctl start k3s'
ssh ubuntu@192.168.7.201 'sudo systemctl start k3s'

# Wait ~30 seconds
sleep 30

# Verify they rejoined
kubectl get nodes

# All masters should show Ready status again
```

## Important Considerations

### 1. Resource Usage

**Before conversion:**
- Master: Runs control plane components (~500MB-1GB RAM)
- Workers: Run only workloads (~100-200MB RAM)

**After conversion:**
- All nodes: Run control plane + workloads (~500MB-1GB RAM each)
- Higher resource usage per node
- More resilient but less efficient for pure workload nodes

### 2. Quorum Requirements

With 4 control plane nodes:
- ✅ Can tolerate 1 master failure (3 remaining)
- ✅ Can tolerate 2 master failures (2 remaining, but no quorum)
- ⚠️  If 3 masters fail, cluster loses quorum

For production, consider:
- **3 masters**: Can tolerate 1 failure
- **5 masters**: Can tolerate 2 failures (recommended for large clusters)

### 3. Network Requirements

All control plane nodes must:
- Communicate on port 6443 (Kubernetes API)
- Communicate on ports 2379-2380 (etcd)
- Have stable IP addresses
- Be able to reach each other

### 4. Kubeconfig Configuration

You can use any master node's kubeconfig:

```bash
# Use first master
ssh ubuntu@192.168.7.200 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/192.168.7.200/g" > ~/.kube/config-homelabs

# Or use any other master as backup
ssh ubuntu@192.168.7.201 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/192.168.7.201/g" > ~/.kube/config-homelabs-backup
```

### 5. Load Balancer/VIP (Optional)

For true HA, consider setting up a load balancer or Virtual IP:

```
┌─────────────┐
│ Load Balancer│
│ 192.168.7.10 │
└──────┬───────┘
       │
   ┌───┴───┬───┬───┐
   │       │   │   │
┌──▼──┐ ┌──▼──┐ ┌──▼──┐ ┌──▼──┐
│ M1  │ │ M2  │ │ M3  │ │ M4  │
└─────┘ └─────┘ └─────┘ └─────┘
```

Then configure kubectl to use the VIP instead of a specific master IP.

## Troubleshooting

### Node Not Joining as Control Plane

```bash
# Check k3s service status
ssh ubuntu@192.168.7.201 'sudo systemctl status k3s'

# Check k3s logs
ssh ubuntu@192.168.7.201 'sudo journalctl -u k3s -f'

# Verify network connectivity
ssh ubuntu@192.168.7.201 'nc -zv 192.168.7.200 6443'
```

### etcd Issues

```bash
# Check etcd pods
kubectl get pods -n kube-system | grep etcd

# Check etcd status
kubectl exec -n kube-system etcd-<node-name> -- etcdctl endpoint health

# Check etcd logs
kubectl logs -n kube-system -l component=etcd
```

### Token Issues

If you lose the token:

```bash
# Get token from any master
ssh ubuntu@192.168.7.200 'sudo cat /var/lib/rancher/k3s/server/node-token'
```

## Reverting to Worker Nodes

If you want to convert a node back to worker-only:

```bash
# On the node to convert back
ssh ubuntu@192.168.7.201

# Uninstall k3s server
sudo /usr/local/bin/k3s-uninstall.sh

# Install as agent (worker)
K3S_TOKEN=$(ssh ubuntu@192.168.7.200 'sudo cat /var/lib/rancher/k3s/server/node-token')
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.7.200:6443" \
  K3S_TOKEN="${K3S_TOKEN}" sudo sh -s - agent \
  --node-ip "192.168.7.201" \
  --node-external-ip "192.168.7.201"
```

## Benefits vs Trade-offs

### Benefits ✅
- **High Availability**: Any node can act as master
- **Fault Tolerance**: Cluster continues if masters fail
- **Automatic Recovery**: Failed masters rejoin automatically
- **Simplified Architecture**: No distinction between master/worker

### Trade-offs ⚠️
- **Higher Resource Usage**: All nodes run control plane components
- **More Complex**: More etcd members to manage
- **Network Overhead**: More etcd replication traffic
- **Not Ideal for Large Clusters**: Better to have dedicated control plane nodes

## When to Use This Setup

**Good for:**
- Small clusters (3-5 nodes)
- Homelabs where you want maximum resilience
- Learning/testing HA setups
- Clusters where all nodes have similar resources

**Not ideal for:**
- Large production clusters (10+ nodes)
- Clusters with resource-constrained nodes
- Clusters where you want to optimize for workload capacity

## References

- [k3s HA Documentation](https://docs.k3s.io/installation/high-availability)
- [k3s Embedded etcd HA](https://docs.k3s.io/datastore/ha-embedded)
- [Kubernetes Control Plane Components](https://kubernetes.io/docs/concepts/overview/components/)
