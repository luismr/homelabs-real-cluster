# Homelabs 4-Node Ubuntu Cluster

A 4-node Ubuntu 24.04 LTS cluster on physical machines, managed over SSH.

## Cluster Configuration

| Node     | IP Address      | CPU | RAM  | Storage | SSH Port | User   |
|----------|-----------------|-----|------|---------|----------|--------|
| master   | 192.168.7.200   | 2   | 4GB  | 932GB SSD | 22     | ubuntu |
| worker-1 | 192.168.7.201   | 2   | 4GB  | -       | 22       | ubuntu |
| worker-2 | 192.168.7.202   | 2   | 4GB  | -       | 22       | ubuntu |
| worker-3 | 192.168.7.203   | 2   | 4GB  | -       | 22       | ubuntu |

Replace IPs above with your actual node IPs in `scripts/cluster-hosts.env`.

**Note**: All nodes run Ubuntu 24.04 LTS with the `ubuntu` user. Root access requires `sudo -s`.

### Shared Storage
- **Master Node**: 932GB NVMe SSD mounted at `/mnt/shared` (XFS filesystem)
- **NFS Server**: Exports `/mnt/shared` to all cluster nodes
- **Samba Server**: Windows/SMB sharing for cross-platform access
- **Available Space**: 914GB usable storage

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────────┐
│                           INTERNET                                │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │              Cloudflare Network (Global CDN)               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │  pudim.dev   │  │luismachado   │  │ carimbo.vip  │      │   │
│  │  │   (DNS)      │  │ reis.dev     │  │   (DNS)      │      │   │
│  │  │   CNAME ──────────▶ CNAME ────────────▶ CNAME    │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │           │                 │                 │            │   │
│  │           └─────────────────┼─────────────────┘            │   │
│  │                             ▼                              │   │
│  │              ┌──────────────────────────┐                  │   │
│  │              │  Cloudflare Tunnel       │                  │   │
│  │              │  (Encrypted Connection)  │                  │   │
│  │              └──────────────┬───────────┘                  │   │
│  └─────────────────────────────┼──────────────────────────────┘   │
└────────────────────────────────┼──────────────────────────────────┘
                                 │ Token Auth
                                 │ HTTPS/QUIC
                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (k3s)                       │
│                    192.168.7.200-203 (/16 subnet)                 │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │ Namespace: cloudflare-tunnel                              │    │
│  │  ┌────────────────────────────────────────────────────┐   │    │
│  │  │ cloudflared pods (x2 replicas)                     │   │    │
│  │  │ Routes traffic based on hostname                   │   │    │
│  │  └─────┬──────────────┬──────────────┬─────────────────   │    │
│  └────────┼──────────────┼──────────────┼────────────────────┘    │
│           │              │              │                         │
│           ▼              ▼              ▼                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                   │
│  │Namespace:  │  │Namespace:  │  │Namespace:  │                   │
│  │pudim-dev   │  │luismachado │  │carimbo-vip │                   │
│  │            │  │  reis-dev  │  │            │                   │
│  │ ┌────────┐ │  │ ┌────────┐ │  │ ┌────────┐ │                   │
│  │ │Service │ │  │ │Service │ │  │ │Service │ │                   │
│  │ │ static │ │  │ │ static │ │  │ │ static │ │                   │
│  │ │ -site  │ │  │ │ -site  │ │  │ │ -site  │ │                   │
│  │ │ClusterIP││  │ │ClusterIP││  │ │ClusterIP││                   │
│  │ └───┬────┘ │  │ └───┬────┘ │  │ └───┬────┘ │                   │
│  │     │      │  │     │      │  │     │      │                   │
│  │ ┌───▼────┐ │  │ ┌───▼────┐ │  │ ┌───▼────┐ │                   │
│  │ │Nginx   │ │  │ │Nginx   │ │  │ │Nginx   │ │                   │
│  │ │Pods x3 │ │  │ │Pods x3 │ │  │ │Pods x3 │ │                   │
│  │ └───┬────┘ │  │ └───┬────┘ │  │ └───┬────┘ │                   │
│  │     │      │  │     │      │  │     │      │                   │
│  │ ┌───▼────┐ │  │ ┌───▼────┐ │  │ ┌───▼────┐ │                   │
│  │ │PVC     │ │  │ │PVC     │ │  │ │PVC     │ │                   │
│  │ │(NFS)   │ │  │ │(NFS)   │ │  │ │(NFS)   │ │                   │
│  │ │1Gi     │ │  │ │1Gi     │ │  │ │1Gi     │ │                   │
│  │ └───┬────┘ │  │ └───┬────┘ │  │ └───┬────┘ │                   │
│  └─────┼──────┘  └─────┼──────┘  └─────┼──────┘                   │
│        │                │                │                        │
│        └────────────────┼────────────────┘                        │
│                         ▼                                         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │          NFS/Samba Server (Master Node: 192.168.7.200)      │  │
│  │          Shared Storage: /mnt/shared/ (932GB XFS)           │  │
│  │          NFS: 192.168.7.200:/mnt/shared                     │  │
│  │          SMB: \\192.168.7.200\shared                        │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Namespace: monitoring                                       │  │
│  │  Prometheus | Grafana | Loki | Alertmanager | Promtail      │  │
│  └─────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘

Legend:
→  HTTP/HTTPS Traffic Flow
┌─ Kubernetes Namespace Boundary
│  Service/Pod/Resource
```

**Traffic Flow:**
1. User requests `pudim.dev`, `luismachadoreis.dev`, or `carimbo.vip`
2. DNS resolves to Cloudflare's network (CNAME → tunnel UUID)
3. Cloudflare routes to your Cloudflare Tunnel (encrypted, token-authenticated)
4. Tunnel pods inspect hostname and route to appropriate namespace service
5. Service load-balances across 3 nginx pod replicas
6. Nginx serves static content from the container image (NFS optional)

## Project Structure

```
homelabs/
├── README.md                    ← You are here
├── docs/                        ← Documentation
│   ├── CLUSTER-INFO.md         ← Quick reference & access info
│   ├── SETUP-GUIDE.md          ← Complete setup tutorial
│   ├── SHARED-STORAGE-GUIDE.md ← Complete NFS & Samba sharing guide
│   ├── NFS-STORAGE-GUIDE.md    ← NFS Kubernetes integration
│   ├── LOKI-GUIDE.md           ← Log collection guide
│   ├── CLOUDFLARE-TUNNEL-SETUP.md ← Cloudflare Tunnel setup
│   └── GIT-QUICK-REFERENCE.md  ← Git commands reference
├── scripts/                     ← Installation & helper scripts
│   ├── setup-cluster.sh         ← Automated cluster setup
│   ├── install-k3s-master.sh    ← Master node installation
│   ├── install-k3s-worker.sh    ← Worker node installation
│   ├── install-observability.sh ← Monitoring stack installation
│   ├── cluster-hosts.env        ← SSH user/key and node IPs
│   ├── setup-nfs-complete.sh    ← Complete NFS setup
│   ├── setup-nfs-server.sh      ← NFS server setup
│   ├── setup-nfs-clients.sh     ← NFS client setup
│   ├── deploy-nfs-provisioner.sh ← NFS CSI provisioner
│   ├── verify-cluster.sh        ← Cluster health check
│   └── ssh-nodes.sh             ← SSH helper
└── examples/                    ← Example manifests
    ├── nfs-test-deployment.yaml ← NFS test example
    ├── nfs-nginx-deployment.yaml ← Nginx with NFS
    └── nfs-statefulset.yaml     ← StatefulSet with NFS
```

## Quick Start

1) Configure SSH and hosts

```bash
# Edit the hosts file with your IPs/hostnames and SSH user/key
$EDITOR scripts/cluster-hosts.env
```

2) Ensure passwordless SSH access to all nodes for the configured user.

3) Provision the cluster

```bash
./scripts/setup-cluster.sh
```

### SSH Access

Ensure your SSH public key is installed on all nodes for your chosen `SSH_USER` (default: `root`).

#### Direct SSH Access

```bash
ssh <user>@<MASTER_IP>
ssh <user>@<WORKER1_IP>
ssh <user>@<WORKER2_IP>
ssh <user>@<WORKER3_IP>
```

#### Using the Helper Script

```bash
# Quick access using the helper script
./scripts/ssh-nodes.sh master   # or: ./scripts/ssh-nodes.sh m
./scripts/ssh-nodes.sh worker1  # or: ./scripts/ssh-nodes.sh w1
./scripts/ssh-nodes.sh worker2  # or: ./scripts/ssh-nodes.sh w2
./scripts/ssh-nodes.sh worker3  # or: ./scripts/ssh-nodes.sh w3
```

 

## Features

- ✅ Ubuntu 24.04 LTS 64-bit
- ✅ Static IPs on your LAN
- ✅ Kubernetes-ready configuration:
  - Swap disabled
  - IP forwarding enabled
  - Bridge netfilter enabled
  - br_netfilter module loaded
- ✅ SSH key authentication enabled
- ✅ Essential tools installed: curl, jq, net-tools, gnupg
- ✅ Custom DNS configuration
- ✅ Promiscuous mode enabled for networking
- ✅ High-performance shared storage:
  - 932GB NVMe SSD with XFS filesystem
  - NFS server for Linux/Unix clients
  - Samba server for Windows/cross-platform access
  - Dynamic volume provisioning
  - ReadWriteMany support
  - Persistent storage for applications

## Documentation

- **[SETUP-GUIDE.md](docs/SETUP-GUIDE.md)** - Complete step-by-step setup tutorial
- **[CLUSTER-INFO.md](docs/CLUSTER-INFO.md)** - Quick reference and access information
- **[NFS-STORAGE-GUIDE.md](docs/NFS-STORAGE-GUIDE.md)** - NFS shared storage configuration
- **[SHARED-STORAGE-GUIDE.md](docs/SHARED-STORAGE-GUIDE.md)** - Complete NFS & Samba sharing guide
- **[LOKI-GUIDE.md](docs/LOKI-GUIDE.md)** - Log collection and querying guide
- **[CLOUDFLARE-TUNNEL-SETUP.md](docs/CLOUDFLARE-TUNNEL-SETUP.md)** - Cloudflare Tunnel configuration guide
- **[GIT-QUICK-REFERENCE.md](docs/GIT-QUICK-REFERENCE.md)** - Git commands reference
- **[terraform/README.md](terraform/README.md)** - Terraform infrastructure documentation

## Testing Connectivity

```bash
# Ping all nodes (replace with your IPs)
for ip in 192.168.7.{200..203}; do ping -c 1 "$ip"; done

# Or use the helper to connect quickly
./scripts/ssh-nodes.sh master
./scripts/ssh-nodes.sh worker1
```

## k3s Cluster with Observability

### Quick Setup

Run the automated setup script to install k3s with full observability:

```bash
./scripts/setup-cluster.sh
```

This will:
1. Install k3s on the master node (`MASTER_IP` from `cluster-hosts.env`)
2. Join all 3 worker nodes to the cluster
3. Set up kubectl access on your local machine
4. Install Prometheus, Grafana, and Loki for observability

### Manual Installation

If you prefer manual control:

```bash
# 1. Install k3s master
ssh <user>@<MASTER_IP> "bash -s -- <MASTER_IP>" < scripts/install-k3s-master.sh

# 2. Get the node token
NODE_TOKEN=$(ssh <user>@<MASTER_IP> 'sudo cat /var/lib/rancher/k3s/server/node-token')

# 3. Install workers
ssh <user>@<WORKER1_IP> "bash -s -- <MASTER_IP> $NODE_TOKEN" < scripts/install-k3s-worker.sh
ssh <user>@<WORKER2_IP> "bash -s -- <MASTER_IP> $NODE_TOKEN" < scripts/install-k3s-worker.sh
ssh <user>@<WORKER3_IP> "bash -s -- <MASTER_IP> $NODE_TOKEN" < scripts/install-k3s-worker.sh

# 4. Copy kubeconfig
ssh <user>@<MASTER_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/<MASTER_IP>/g" > ~/.kube/config-homelabs
export KUBECONFIG=~/.kube/config-homelabs

# 5. Install observability stack
scp scripts/install-observability.sh <user>@<MASTER_IP>:/tmp/
ssh <user>@<MASTER_IP> 'bash /tmp/install-observability.sh'
```

### Observability Stack

**Included Components:**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Alertmanager**: Alert management
- **Node Exporter**: Host-level metrics
- **Promtail**: Log collection agent

**Access URLs (replace with your master IP):**
- **Grafana**: http://<MASTER_IP>:30080
  - Username: `admin`
  - Password: `admin`
- **Prometheus**: http://<MASTER_IP>:30090
- **Alertmanager**: http://<MASTER_IP>:30093

**Pre-configured Dashboards:**
- Kubernetes Cluster Overview
- Namespace Resources
- Node Resources
- Pod Resources
- Node Exporter Metrics

### kubectl Commands

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/config-homelabs

# View cluster nodes
kubectl get nodes -o wide

# View all pods
kubectl get pods -A

# View monitoring stack
kubectl get all -n monitoring

# Access Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f
```

## Shared Storage

The master node provides both NFS and Samba/Windows sharing from a high-performance 932GB NVMe SSD.

### Storage Details
- **Device**: `/dev/nvme0n1p1` (932GB NVMe SSD)
- **Filesystem**: XFS (optimized for performance)
- **Mount Point**: `/mnt/shared`
- **Available Space**: 914GB usable storage

### NFS Server (Linux/Unix Access)

**Exports**: `/mnt/shared` accessible from all cluster nodes
**Allowed Clients**: 192.168.7.200-203 (all cluster nodes)

```bash
# Mount from any cluster node
sudo mount -t nfs 192.168.7.200:/mnt/shared /local/mount/point

# Verify exports
showmount -e 192.168.7.200
```

### Samba Server (Windows/Cross-Platform Access)

**Share Name**: `shared`
**Access**: Anonymous/guest access from 192.168.0.0/16 network

```bash
# Windows access
\\192.168.7.200\shared

# Linux Samba mount
sudo mount -t cifs //192.168.7.200/shared /local/mount/point -o guest

# List shares
smbclient -L 192.168.7.200 -N
```

### Kubernetes Integration

Create a PersistentVolumeClaim for NFS storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteMany  # Shared access across pods
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client  # Default NFS storage
```

### Setup NFS for Kubernetes

```bash
# Automated setup (recommended)
./scripts/setup-nfs-complete.sh
```

This will:
1. Configure master node as NFS server
2. Install NFS clients on all workers  
3. Deploy NFS CSI driver for dynamic provisioning
4. Create StorageClasses for your applications

### Test Shared Storage

```bash
# Deploy test pods
kubectl apply -f examples/nfs-test-deployment.yaml

# Check if data is shared
kubectl logs nfs-writer
kubectl logs nfs-reader

# Cleanup
kubectl delete -f examples/nfs-test-deployment.yaml
```

### Available Storage Classes

- **nfs-client** (default) - General purpose shared storage
- **nfs-grafana** - Reserved for Grafana (if needed)
- **nfs-prometheus** - Reserved for Prometheus (if needed)
- **nfs-loki** - Reserved for Loki (if needed)

See **[NFS-STORAGE-GUIDE.md](docs/NFS-STORAGE-GUIDE.md)** for complete documentation.

## Terraform Infrastructure

Manage Kubernetes deployments declaratively with Terraform.

### Deployed Static Sites

Three nginx-based static websites managed by Terraform, each in its own namespace:

```bash
# View deployment status
cd terraform
terraform output

# Sites (Production - 3 replicas each):
- pudim.dev           → pudim-dev namespace
- luismachadoreis.dev → luismachadoreis-dev namespace  
- carimbo.vip         → carimbo-vip namespace
```



### Quick Commands

```bash
# Check all deployments
kubectl get pods -A | grep -E "(pudim|luis|carimbo)"

# View specific site
kubectl get all -n pudim-dev

# Roll out a new image (example with kubectl)
kubectl -n pudim-dev set image deployment/pudim-dev nginx=ghcr.io/ORG/pudim:latest
kubectl -n pudim-dev rollout status deployment/pudim-dev --timeout=120s

# Or set images via Terraform variables and apply
# in terraform/terraform.tfvars
pudim_site_image           = "ghcr.io/ORG/pudim:latest"
luismachadoreis_site_image = "ghcr.io/ORG/luis:latest"
carimbo_site_image         = "ghcr.io/ORG/carimbo:latest"

# If images are private on GHCR (requires read:packages token)
ghcr_username = "your-gh-username-or-org"
ghcr_token    = "ghp_xxx"
```

### Adding Cloudflare Tunnel

To expose sites publicly:

1. Get tunnel token from [Cloudflare Dashboard](https://one.dash.cloudflare.com/)
2. Update `terraform/terraform.tfvars`:
   ```hcl
   cloudflare_tunnel_token = "your-token-here"
   ```
3. Apply changes:
   ```bash
   cd terraform
   terraform apply
   ```

See **[CLOUDFLARE-TUNNEL-SETUP.md](docs/CLOUDFLARE-TUNNEL-SETUP.md)** and **[terraform/README.md](terraform/README.md)** for detailed guides.

## Next Steps

This cluster is now ready for:
- Deploying containerized applications
- Testing distributed systems
- Running CI/CD pipelines
- Database clustering (PostgreSQL, MongoDB, etc.)
- Service mesh experimentation (Istio, Linkerd)

## Troubleshooting

### Redirects (nginx-redirector)

- Namespace: `redirects`
- Internal service: `http://redirector.redirects.svc.cluster.local:80`
- Purpose: 301 HTTPS redirects from legacy domains to canonical domains. Wildcards mirror subdomains and preserve path/query.
- Autoscaling: 1–4 pods via HPA (CPU 60%, Memory 70%).

Current rules:
- `luismachadoreis.dev.br`, `*.luismachadoreis.dev.br` → `luismachadoreis.dev`, `*.luismachadoreis.dev`
- `pudim.dev.br`, `*.pudim.dev.br` → `pudim.dev`, `*.pudim.dev`
- `carimbovip.com(.br)`, `*.carimbovip.com(.br)` → `carimbo.vip`, `*.carimbo.vip`

Test inside the cluster:

```bash
kubectl -n redirects run curl --image=curlimages/curl:8.10.1 --rm -i --restart=Never -- \
  sh -lc "curl -sSI -H 'Host: blog.pudim.dev.br' 'http://redirector.redirects.svc.cluster.local/some/path?q=1'"
# Expect Location: https://blog.pudim.dev/some/path?q=1
```

### SSH connection refused
```bash
# On the node, ensure SSH is running and your public key is installed
sudo systemctl status ssh
cat ~/.ssh/authorized_keys

# Test SSH connectivity from your local machine
ssh ubuntu@192.168.7.200  # master
ssh ubuntu@192.168.7.201  # worker-1
ssh ubuntu@192.168.7.202  # worker-2
ssh ubuntu@192.168.7.203  # worker-3
```

### Root access
```bash
# To become root on Ubuntu nodes
sudo -s

# Or run individual commands with sudo
sudo systemctl status k3s
```

### Performance issues
```bash
# Monitor node resources
kubectl top nodes
kubectl top pods --all-namespaces

# Check system resources on nodes
ssh ubuntu@192.168.7.200 'htop'
```

 

