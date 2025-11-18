# NFS Shared Storage Guide

## Overview

This cluster uses NFS (Network File System) for shared persistent storage across all nodes. The master node (192.168.7.200) acts as an NFS server, providing storage to all worker nodes.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Master Node (NFS Server)                   │
│                    192.168.7.200                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  NFS Exports                                       │    │
│  │  /mnt/shared      - 932GB NVMe SSD (XFS)          │    │
│  │  Available: 914GB usable storage                  │    │
│  │  Dual Protocol: NFS + Samba/Windows sharing       │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────┬───────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐  ┌──────▼──────┐  ┌───────▼────────┐
│  Worker 1      │  │  Worker 2   │  │  Worker 3      │
│  192.168.7.201 │  │ 192.168.7.202│  │ 192.168.7.203  │
│                │  │             │  │                │
│  NFS Client    │  │ NFS Client  │  │ NFS Client     │
│  Mounts from   │  │ Mounts from │  │ Mounts from    │
│  Master        │  │ Master      │  │ Master         │
└────────────────┘  └─────────────┘  └────────────────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
                    ┌──────▼──────┐
                    │ NFS CSI     │
                    │ Provisioner │
                    │             │
                    │ Dynamic PV  │
                    │ Creation    │
                    └─────────────┘
```

## Setup

### Automated Setup (Recommended)

Run the complete NFS setup script:

```bash
./scripts/setup-nfs-complete.sh
```

This will:
1. Install and configure NFS server on master
2. Install NFS clients on all workers
3. Deploy NFS CSI driver to Kubernetes
4. Create StorageClasses for dynamic provisioning

### Manual Setup

If you prefer manual control:

```bash
# 1. Setup NFS server on master
ssh ubuntu@192.168.7.200 < scripts/setup-nfs-server.sh

# 2. Setup NFS clients on workers
for ip in 192.168.7.201 192.168.7.202 192.168.7.203; do
  ssh ubuntu@$ip "bash -s -- 192.168.7.200" < scripts/setup-nfs-clients.sh
done

# 3. Deploy NFS CSI provisioner
scp scripts/deploy-nfs-provisioner.sh ubuntu@192.168.7.200:/tmp/
ssh ubuntu@192.168.7.200 'bash /tmp/deploy-nfs-provisioner.sh'
```

## Available StorageClasses

After setup, you'll have these StorageClasses:

| StorageClass | NFS Path | Purpose | Default |
|--------------|----------|---------|---------|
| nfs-client | /nfs/shared | General purpose storage | ✅ Yes |
| nfs-grafana | /nfs/grafana | Reserved for Grafana | No |
| nfs-prometheus | /nfs/prometheus | Reserved for Prometheus | No |
| nfs-loki | /nfs/loki | Reserved for Loki | No |
| nfs-alertmanager | /nfs/alertmanager | Reserved for Alertmanager | No |

### Verify Setup

```bash
# Check StorageClasses
kubectl get storageclass

# Check NFS CSI driver pods
kubectl get pods -n nfs-system

# Check NFS exports on server
ssh ubuntu@192.168.7.200 'showmount -e localhost'
```

## Using NFS Storage

### Example 1: Simple PersistentVolumeClaim

Create a PVC that uses the default NFS storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteMany  # NFS supports shared access
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client  # Uses NFS
```

### Example 2: Deployment with NFS Storage

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: my-app-storage
```

### Example 3: StatefulSet with NFS

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web"
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteMany" ]
      storageClassName: "nfs-client"
      resources:
        requests:
          storage: 1Gi
```

### Example 4: Shared Storage Between Pods

Perfect for shared configuration or data:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-config
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Mi
  storageClassName: nfs-client
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c', 'while true; do date >> /shared/app1.log; sleep 5; done']
        volumeMounts:
        - name: shared
          mountPath: /shared
      volumes:
      - name: shared
        persistentVolumeClaim:
          claimName: shared-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c', 'while true; do cat /shared/app1.log 2>/dev/null || echo "Waiting..."; sleep 5; done']
        volumeMounts:
        - name: shared
          mountPath: /shared
      volumes:
      - name: shared
        persistentVolumeClaim:
          claimName: shared-config  # Same PVC, shared access!
```

## Testing NFS Storage

### Quick Test

Save this as `test-nfs-pvc.yaml`:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
---
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-writer
spec:
  containers:
  - name: writer
    image: busybox
    command:
      - sh
      - -c
      - |
        echo "Writing test data..."
        echo "Hello from $(hostname) at $(date)" > /data/test.txt
        echo "File created. Sleeping..."
        sleep 3600
    volumeMounts:
    - name: nfs-volume
      mountPath: /data
  volumes:
  - name: nfs-volume
    persistentVolumeClaim:
      claimName: test-nfs
---
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-reader
spec:
  containers:
  - name: reader
    image: busybox
    command:
      - sh
      - -c
      - |
        echo "Reading test data..."
        while true; do
          cat /data/test.txt 2>/dev/null || echo "Waiting for file..."
          sleep 5
        done
    volumeMounts:
    - name: nfs-volume
      mountPath: /data
  volumes:
  - name: nfs-volume
    persistentVolumeClaim:
      claimName: test-nfs
```

Deploy and test:

```bash
# Deploy test
kubectl apply -f test-nfs-pvc.yaml

# Check PVC status
kubectl get pvc test-nfs

# Check if writer created file
kubectl logs test-nfs-writer

# Check if reader can see the file
kubectl logs test-nfs-reader

# Cleanup
kubectl delete -f test-nfs-pvc.yaml
```

## Storage Management

### View NFS Usage

```bash
# On master node
ssh ubuntu@192.168.7.200 'sudo df -h /nfs/*'

# From kubectl
kubectl get pv
kubectl get pvc -A
```

### List NFS Exports

```bash
ssh ubuntu@192.168.7.200 'sudo exportfs -v'
```

### Resize NFS Share

NFS exports can grow dynamically (limited by host disk):

```bash
# Check available space on master
ssh ubuntu@192.168.7.200 'df -h /'

# Resize PVC (if supported by CSI driver)
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'
```

## Access Modes

NFS supports all Kubernetes access modes:

| Mode | Abbreviation | Description | NFS Support |
|------|--------------|-------------|-------------|
| ReadWriteOnce | RWO | Single node read-write | ✅ Yes |
| ReadOnlyMany | ROX | Multiple nodes read-only | ✅ Yes |
| ReadWriteMany | RWM | Multiple nodes read-write | ✅ Yes |

This makes NFS perfect for:
- Shared configuration
- Shared media files
- Shared cache
- StatefulSets that need to share data

## Backup & Restore

### Backup NFS Data

```bash
# From master node
ssh ubuntu@192.168.7.200 'sudo tar -czf /tmp/nfs-backup-$(date +%Y%m%d).tar.gz -C /nfs .'

# Copy to local machine
scp ubuntu@192.168.7.200:/tmp/nfs-backup-*.tar.gz ./backups/
```

### Restore NFS Data

```bash
# Copy backup to master
scp ./backups/nfs-backup-*.tar.gz ubuntu@192.168.7.200:/tmp/

# Extract on master
ssh ubuntu@192.168.7.200 'sudo tar -xzf /tmp/nfs-backup-*.tar.gz -C /nfs/'
```

## Troubleshooting

### PVC Stuck in Pending

```bash
# Check PVC events
kubectl describe pvc <pvc-name>

# Check NFS CSI driver
kubectl get pods -n nfs-system
kubectl logs -n nfs-system -l app=csi-nfs-controller

# Check StorageClass
kubectl get storageclass
```

### Mount Errors

```bash
# Check NFS server is running
ssh ubuntu@192.168.7.200 'sudo systemctl status nfs-kernel-server'

# Check exports
ssh ubuntu@192.168.7.200 'showmount -e localhost'

# Check from worker
ssh ubuntu@192.168.7.201 'showmount -e 192.168.7.200'

# Test mount manually
ssh ubuntu@192.168.7.201 'sudo mount -t nfs 192.168.7.200:/nfs/shared /mnt/test'
```

### Permission Issues

```bash
# Check permissions on NFS server
ssh ubuntu@192.168.7.200 'sudo ls -la /nfs/'

# Fix permissions if needed
ssh ubuntu@192.168.7.200 'sudo chmod -R 777 /nfs/ && sudo chown -R nobody:nogroup /nfs/'
```

### Performance Issues

```bash
# Check NFS statistics
ssh ubuntu@192.168.7.200 'sudo nfsstat'

# Check network latency
ping -c 10 192.168.7.200

# Monitor I/O
ssh ubuntu@192.168.7.200 'iostat -x 5'
```

## Advanced Configuration

### Custom StorageClass

Create a custom StorageClass for specific needs:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-fast
provisioner: nfs.csi.k8s.io
parameters:
  server: 192.168.7.200
  share: /nfs/shared
  mountPermissions: "0755"
reclaimPolicy: Delete  # or Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard
  - timeo=600
  - retrans=2
  - rsize=1048576  # 1MB read size
  - wsize=1048576  # 1MB write size
```

### ReadOnly Volumes

For shared read-only data:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-readonly
spec:
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
```

## Performance Considerations

### NFS Performance Tips

1. **Use NFSv4.1** - Better performance than v3
2. **Adjust rsize/wsize** - Larger sizes for better throughput
3. **Use hard mounts** - Prevents data corruption
4. **Monitor network** - NFS is network-dependent
5. **Consider caching** - Use local caching for read-heavy workloads

### When NOT to Use NFS

Avoid NFS for:
- ❌ Database data files (use local NVMe/SSD instead)
- ❌ High-IOPS workloads
- ❌ Latency-sensitive applications
- ❌ Small random writes

Good uses for NFS:
- ✅ Shared configuration files
- ✅ Media files (images, videos)
- ✅ Backup storage
- ✅ Log aggregation
- ✅ Shared cache
- ✅ Static website content

## Security

### Network Security

NFS is limited to the cluster subnet:

```bash
# Only 192.168.7.0/24 can access
# Configured in /etc/exports on master
```

### Disable Root Squash (Current Config)

```
no_root_squash  # Root on client = Root on server
```

**Security Note**: In production, consider using `root_squash` and proper user mapping.

## Monitoring NFS

### Check NFS Stats

```bash
# On master
ssh ubuntu@192.168.7.200 'sudo nfsstat -s'

# NFS operations
watch -n 2 'ssh ubuntu@192.168.7.200 sudo nfsstat -s'
```

### Prometheus Metrics

You can deploy an NFS exporter for Prometheus metrics:

```bash
# Example: Deploy node-exporter with NFS stats
kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/crds/crd-servicemonitors.yaml
```

## Migration from Local Storage

If you want to migrate existing apps to NFS:

1. **Backup data** from current PV
2. **Create NFS PVC** with same size
3. **Copy data** to NFS PVC
4. **Update deployment** to use new PVC
5. **Delete old PVC**

Example migration:

```bash
# 1. Create migration pod with both volumes
kubectl run migrator --image=busybox --rm -it --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "migrator",
      "image": "busybox",
      "command": ["sh"],
      "volumeMounts": [
        {"name": "old", "mountPath": "/old"},
        {"name": "new", "mountPath": "/new"}
      ]
    }],
    "volumes": [
      {"name": "old", "persistentVolumeClaim": {"claimName": "old-pvc"}},
      {"name": "new", "persistentVolumeClaim": {"claimName": "new-nfs-pvc"}}
    ]
  }
}' -- sh -c "cp -av /old/* /new/"
```

## Summary

### ✅ What You Get

- **Shared storage** across all nodes
- **Dynamic provisioning** via NFS CSI driver
- **Multiple access modes** (RWO, ROX, RWM)
- **Easy to use** - just create a PVC
- **Persistent** - survives pod restarts
- **Dedicated exports** for different purposes

### 🎯 Quick Reference

```bash
# Setup NFS
./scripts/setup-nfs-complete.sh

# Check status
kubectl get storageclass
kubectl get pvc -A
kubectl get pv

# Create PVC
kubectl apply -f my-pvc.yaml

# Test NFS
kubectl apply -f test-nfs-pvc.yaml
kubectl logs test-nfs-reader

# Troubleshoot
kubectl describe pvc <name>
kubectl get pods -n nfs-system
ssh ubuntu@192.168.7.200 'showmount -e localhost'
```

### 📚 More Information

- **NFS Documentation**: https://linux-nfs.org/wiki/index.php/Main_Page
- **NFS CSI Driver**: https://github.com/kubernetes-csi/csi-driver-nfs
- **Kubernetes Storage**: https://kubernetes.io/docs/concepts/storage/

---

**Note**: This NFS setup does NOT affect existing Grafana, Prometheus, or Loki installations. It provides shared storage for new applications only.

