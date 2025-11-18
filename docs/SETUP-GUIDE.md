# Complete Homelab Setup Guide
## 4-Node k3s Cluster with Full Observability Stack

**Time to Complete**: ~30-45 minutes  
**Difficulty**: Intermediate  
**Cost**: Free (all open-source tools)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step 1: Prepare Ubuntu Machines](#step-1-prepare-ubuntu-machines)
4. [Step 2: Configure SSH Access](#step-2-configure-ssh-access)
5. [Step 3: Install k3s Cluster](#step-3-install-k3s-cluster)
6. [Step 4: Install Observability Stack](#step-4-install-observability-stack)
7. [Step 5: Verify Installation](#step-5-verify-installation)
8. [Step 6: Explore Grafana Dashboards](#step-6-explore-grafana-dashboards)
9. [Step 7: Deploy Sample Application](#step-7-deploy-sample-application)
10. [Troubleshooting](#troubleshooting)
11. [Daily Operations](#daily-operations)
12. [Cleanup and Maintenance](#cleanup-and-maintenance)

---

## Quick Start (Physical Machines)

This guide sets up a 4-node k3s cluster on physical Ubuntu machines accessed over SSH.

**Prerequisites:**
- 4x Ubuntu 24.04 LTS machines with static IPs (1 master, 3 workers)
- SSH keys copied to all machines: `ssh-copy-id ubuntu@<machine-ip>`
- Root access via `sudo -s` on all machines
- Worker nodes named: worker-1, worker-2, worker-3

**Quick Setup:**
1. Edit `scripts/cluster-hosts.env` with your IPs and SSH settings
2. Run the automated installer: `./scripts/setup-cluster.sh`
3. Verify the installation: `./scripts/verify-cluster.sh`

For detailed setup instructions, continue with the steps below.

---

## Prerequisites

### Physical Machines

- **4x Ubuntu 24.04 LTS machines** with static IP addresses
- **Network**: All machines on the same subnet (192.168.0.0/16 in this guide)
- **SSH Access**: Passwordless SSH configured to all machines
- **User**: `ubuntu` user with sudo privileges on all machines

### Your Local Machine

- **SSH Client**: OpenSSH (pre-installed on macOS/Linux)
- **kubectl**: Kubernetes CLI tool
- **Network Access**: Ability to reach the cluster machines

### Network Requirements

- **Ports**: 22 (SSH), 6443 (k3s API), 30080 (Grafana), 30090 (Prometheus), 30093 (Alertmanager)
- **DNS**: Internet access for downloading packages
- **Firewall**: Allow traffic between cluster nodes

### Knowledge Requirements

- Basic command-line skills
- Understanding of SSH key authentication
- Familiarity with YAML (helpful but not required)
- Basic Kubernetes concepts (helpful but not required)

---

## Architecture Overview

### Cluster Design

```
                    ┌─────────────────────────────────────┐
                    │     Your Local Machine               │
                    │  - kubectl configured               │
                    │  - SSH access to all nodes          │
                    │  - Browser access to dashboards     │
                    └──────────────┬──────────────────────┘
                                   │ SSH
                    ┌──────────────┴──────────────┐
                    │  192.168.0.0/16 Network     │
                    │  (Physical LAN)              │
                    └──────────────┬──────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
┌───────▼────────┐    ┌───────────▼─────┐    ┌──────────────▼──────┐
│  Master Node   │    │  Worker-1 Node   │    │  Worker-2 & 3 Nodes │
│ 192.168.7.200  │    │ 192.168.7.201    │    │ 192.168.7.202-203   │
│ Ubuntu 24.04   │    │ Ubuntu 24.04     │    │ Ubuntu 24.04        │
│                │    │                  │    │                     │
│ - k3s server   │    │ - k3s agent      │    │ - k3s agent         │
│ - etcd         │    │ - Workloads      │    │ - Workloads         │
│ - API server   │    │                  │    │                     │
│ - Monitoring   │    │                  │    │                     │
│   Stack:       │    │                  │    │                     │
│   • Prometheus │    │                  │    │                     │
│   • Grafana    │    │                  │    │                     │
│   • Loki       │    │                  │    │                     │
│                │    │                  │    │                     │
│ 2+ CPU / 4GB   │    │ 2+ CPU / 4GB     │    │ 2+ CPU / 4GB each   │
└────────────────┘    └──────────────────┘    └─────────────────────┘
```

### Components

| Component | Purpose | Port |
|-----------|---------|------|
| **k3s** | Lightweight Kubernetes distribution | 6443 |
| **Prometheus** | Metrics collection and storage | 30090 |
| **Grafana** | Visualization and dashboards | 30080 |
| **Loki** | Log aggregation | 3100 |
| **Alertmanager** | Alert management | 30093 |
| **Node Exporter** | Host metrics | 9100 |
| **Promtail** | Log collection agent | 9080 |

### Network Configuration

- **Subnet**: 192.168.0.0/16 (255.255.0.0)
- **Master**: 192.168.7.200
- **Workers**: 192.168.7.201-203
- **DNS**: 1.1.1.1, 8.8.8.8, 8.8.4.4

---

## Step 1: Prepare Ubuntu Machines

### 1.1: Install Ubuntu 24.04 LTS

Install Ubuntu 24.04 LTS on your 4 physical machines:
- 1x Master node (192.168.7.200)
- 3x Worker nodes (192.168.7.201-203)

**Requirements per machine:**
- 2+ CPU cores
- 4GB+ RAM
- 20GB+ disk space
- Static IP address configured
- Internet connectivity

### 1.2: Configure Static IPs

On each Ubuntu machine, configure static IP addresses. Edit `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:  # Replace with your interface name
      dhcp4: false
      addresses:
        - 192.168.7.200/16  # Change per machine
      gateway4: 192.168.1.1  # Your gateway
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
          - 8.8.4.4
```

Apply the configuration:
```bash
sudo netplan apply
```

### 1.3: Update System Packages

On each machine, update the system:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git openssh-server
```

---

## Step 2: Configure SSH Access

### 2.1: Generate SSH Key (on your local machine)

If you don't have an SSH key, generate one:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### 2.2: Copy SSH Key to All Machines

Copy your SSH key to all Ubuntu machines:

```bash
# Copy to master
ssh-copy-id ubuntu@192.168.7.200

# Copy to workers
ssh-copy-id ubuntu@192.168.7.201
ssh-copy-id ubuntu@192.168.7.202
ssh-copy-id ubuntu@192.168.7.203
```

### 2.3: Test SSH Access

Verify passwordless SSH access:

```bash
# Test master
ssh ubuntu@192.168.7.200 "hostname && whoami"

# Test workers
ssh ubuntu@192.168.7.201 "hostname && whoami"
ssh ubuntu@192.168.7.202 "hostname && whoami"
ssh ubuntu@192.168.7.203 "hostname && whoami"
```

### 2.4: Configure Cluster Hosts

Edit `scripts/cluster-hosts.env` with your configuration:

```bash
# SSH user and optional private key
SSH_USER="ubuntu"
SSH_KEY=""   # Leave empty to use default

# Master node IP
MASTER_IP="192.168.7.200"

# Worker nodes IPs (space-separated)
WORKER_IPS="192.168.7.201 192.168.7.202 192.168.7.203"

# Worker names (space-separated; must match count of WORKER_IPS)
WORKER_NAMES="worker-1 worker-2 worker-3"
```

---

## Step 3: Install k3s Cluster

### 3.1: Automated Installation

Run the automated cluster setup:

```bash
cd ~/homelabs
./scripts/setup-cluster.sh
```

This script will:
1. Install k3s on the master node
2. Get the node token
3. Install k3s agents on all worker nodes
4. Configure kubectl access

**Expected output**:
```
=== Installing k3s master node ===
...
=== Installing k3s worker nodes ===
...
=== Cluster setup completed successfully ===
```

### 3.2: Manual Installation (Alternative)

If you prefer manual control:

#### 3.2.1: Install k3s Master

```bash
cd ~/homelabs

# Copy script to master
scp scripts/install-k3s-master.sh ubuntu@192.168.7.200:/tmp/

# Execute installation
ssh ubuntu@192.168.7.200 'bash /tmp/scripts/install-k3s-master.sh'
```

#### 3.2.2: Get Node Token

```bash
# Get the token (save this for the next step)
NODE_TOKEN=$(ssh ubuntu@192.168.7.200 'sudo cat /var/lib/rancher/k3s/server/node-token')
echo "Node Token: $NODE_TOKEN"
```

#### 3.2.3: Install k3s Workers

```bash
# Install on all workers simultaneously
for ip in 192.168.7.201 192.168.7.202 192.168.7.203; do
  echo "Installing on $ip..."
  scp scripts/install-k3s-worker.sh ubuntu@$ip:/tmp/
  ssh ubuntu@$ip "bash /tmp/scripts/install-k3s-worker.sh 192.168.7.200 $NODE_TOKEN" &
done

# Wait for all to complete
wait
echo "All workers installed!"
```

### 3.3: Configure kubectl

```bash
# Copy kubeconfig from master
ssh ubuntu@192.168.7.200 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
  sed "s/127.0.0.1/192.168.7.200/g" > ~/.kube/config

# Set permissions
chmod 600 ~/.kube/config

# Test kubectl
kubectl get nodes
```

**Expected output** (wait 30 seconds if nodes show NotReady):
```
NAME      STATUS   ROLES                  AGE   VERSION        INTERNAL-IP     EXTERNAL-IP
master    Ready    control-plane,master   2m    v1.33.5+k3s1   192.168.7.200   192.168.7.200
worker-1  Ready    <none>                 1m    v1.33.5+k3s1   192.168.7.201   192.168.7.201
worker-2  Ready    <none>                 1m    v1.33.5+k3s1   192.168.7.202   192.168.7.202
worker-3  Ready    <none>                 1m    v1.33.5+k3s1   192.168.7.203   192.168.7.203
```

✅ **Checkpoint**: You now have a working 4-node k3s cluster!

---

## Step 4: Install Observability Stack

### 4.1: Automated Installation

```bash
cd ~/homelabs

# Copy script to master
scp scripts/install-observability.sh ubuntu@192.168.7.200:/tmp/

# Execute installation (this takes 5-10 minutes)
ssh ubuntu@192.168.7.200 'bash /tmp/scripts/install-observability.sh'
```

**What happens**:
1. Installs Helm package manager
2. Adds Prometheus and Grafana Helm repositories
3. Creates monitoring namespace
4. Installs kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
5. Installs Loki for log aggregation
6. Configures NodePort services for external access

**Expected output**:
```
=== Installing Observability Stack ===
Installing Helm...
Adding Helm repositories...
Creating monitoring namespace...
Installing kube-prometheus-stack...
Installing Loki...
=== Observability stack installed successfully ===
```

---

## Step 5: Verify Installation

### 5.1: Automated Verification

```bash
./scripts/verify-cluster.sh
```

This script checks:
- kubectl connectivity
- All nodes are Ready
- Monitoring namespace exists
- All monitoring pods are running
- Service endpoints are accessible
- SSH access to all nodes

**Expected output**:
```
╔════════════════════════════════════════════════════════════════╗
║  k3s Cluster Verification                                      ║
╚════════════════════════════════════════════════════════════════╝

🔍 Checking kubectl connectivity...
  ✓ kubectl is configured correctly

🖥️  Checking cluster nodes...
  ✓ All 4 nodes are Ready

📊 Checking observability stack...
  ✓ Monitoring namespace exists
  ✓ Monitoring pods: 12/12 running

🌐 Checking service endpoints...
  ✓ Grafana    : http://192.168.7.200:30080/login
  ✓ Prometheus : http://192.168.7.200:30090/graph
  ✓ Alertmanager: http://192.168.7.200:30093

🔐 Checking SSH access to nodes...
  ✓ master   (192.168.7.200)
  ✓ worker-1 (192.168.7.201)
  ✓ worker-2 (192.168.7.202)
  ✓ worker-3 (192.168.7.203)

🎉 Your k3s cluster with observability is ready!
```

---

## Step 6: Explore Grafana Dashboards

### 6.1: Access Grafana

Open your browser and navigate to:
**http://192.168.7.200:30080**

**Login credentials**:
- Username: `admin`
- Password: `admin`

### 6.2: Pre-installed Dashboards

Explore these dashboards (left sidebar → Dashboards):

1. **Kubernetes / Compute Resources / Cluster** - Overall cluster metrics
2. **Kubernetes / Compute Resources / Namespace** - Per-namespace resources
3. **Kubernetes / Compute Resources / Node** - Individual node details
4. **Kubernetes / Compute Resources / Pod** - Pod-level metrics
5. **Node Exporter / Nodes** - Host system metrics

### 6.3: Explore Logs with Loki

1. Click **Explore** (compass icon in left sidebar)
2. Select **Loki** as data source
3. Try these LogQL queries:
   - `{namespace="kube-system"}` - All system logs
   - `{job="systemd-journal"}` - System journal logs
   - `{namespace="monitoring"}` - Monitoring stack logs

---

## Step 7: Deploy Sample Application

### 7.1: Deploy Nginx

```bash
# Create deployment
kubectl create deployment nginx --image=nginx

# Expose as NodePort service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check the assigned port
kubectl get svc nginx
```

### 7.2: Access the Application

```bash
# Get the NodePort
NODEPORT=$(kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
echo "Nginx is available at: http://192.168.7.200:$NODEPORT"

# Test it
curl http://192.168.7.200:$NODEPORT
```

### 7.3: Monitor in Grafana

1. Go back to Grafana
2. Check the **Kubernetes / Compute Resources / Pod** dashboard
3. You should see your nginx pod metrics

---

## Troubleshooting

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

### Pods not starting
```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check node details
kubectl describe node <node-name>

# SSH to the node
ssh ubuntu@<node-ip>

# Check k3s service
systemctl status k3s  # on master
systemctl status k3s-agent  # on worker
```

---

## Daily Operations

### Starting/Stopping Cluster

```bash
# Check cluster status
kubectl get nodes

# If images are private on GHCR (requires read:packages token)
ghcr_username = "your-gh-username-or-org"
ghcr_token    = "ghp_xxx"
```

### Accessing Nodes

```bash
# Direct SSH
ssh ubuntu@192.168.7.200
ssh ubuntu@192.168.7.201
ssh ubuntu@192.168.7.202
ssh ubuntu@192.168.7.203

# Using helper script
./scripts/ssh-nodes.sh master
./scripts/ssh-nodes.sh worker-1
```

---

## Cleanup and Maintenance

### Updating Observability Stack

```bash
# SSH to master
ssh ubuntu@192.168.7.200

# Update Helm repos
helm repo update

# Upgrade Prometheus stack
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

# Upgrade Loki
helm upgrade loki grafana/loki -n monitoring
```

### Removing k3s

```bash
# On master
ssh ubuntu@192.168.7.200 'sudo /usr/local/bin/k3s-uninstall.sh'

# On workers
ssh ubuntu@192.168.7.201 'sudo /usr/local/bin/k3s-agent-uninstall.sh'
ssh ubuntu@192.168.7.202 'sudo /usr/local/bin/k3s-agent-uninstall.sh'
ssh ubuntu@192.168.7.203 'sudo /usr/local/bin/k3s-agent-uninstall.sh'
```

### Disk Space Management

```bash
# Check disk usage
for ip in 192.168.7.{200..203}; do
  echo "=== $ip ==="
  ssh ubuntu@$ip "df -h /"
done

# Clean Docker/containerd images on nodes
for ip in 192.168.7.{200..203}; do
  ssh ubuntu@$ip "sudo k3s crictl rmi --prune"
done

# Clean up unused Kubernetes resources
kubectl delete pods --field-selector status.phase=Failed -A
kubectl delete pods --field-selector status.phase=Succeeded -A
```

---

## Reference

### IP Allocation

| Node | IP Address | Purpose |
|------|------------|---------|
| master | 192.168.7.200 | Control plane, monitoring |
| worker-1 | 192.168.7.201 | Workloads |
| worker-2 | 192.168.7.202 | Workloads |
| worker-3 | 192.168.7.203 | Workloads |

### Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Grafana | admin | admin |
| SSH (ubuntu) | ubuntu | (key-based) |

### Useful kubectl Commands

```bash
# Context and config
kubectl config current-context
kubectl config view

# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Monitoring specific
kubectl get pods -n monitoring
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

### Documentation Links

- **k3s Documentation**: https://docs.k3s.io/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **Loki Documentation**: https://grafana.com/docs/loki/

### Checklist

- [ ] All 4 Ubuntu machines prepared and accessible
- [ ] SSH access working to all nodes
- [ ] k3s cluster deployed and all nodes Ready
- [ ] Observability stack installed and accessible
- [ ] Grafana dashboards working
- [ ] Sample application deployed and monitored

---

🎉 **Congratulations!** Your 4-node k3s cluster with full observability is ready for production workloads!
