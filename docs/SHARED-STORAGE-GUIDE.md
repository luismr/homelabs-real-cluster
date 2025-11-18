# Shared Storage Guide: NFS & Samba

Complete guide for the cluster's shared storage system featuring both NFS (Network File System) and Samba/Windows sharing from a high-performance NVMe SSD.

## Overview

The master node (192.168.7.200) provides dual-protocol shared storage:
- **NFS Server**: For Linux/Unix systems and Kubernetes
- **Samba Server**: For Windows systems and cross-platform compatibility
- **Storage Backend**: 932GB NVMe SSD with XFS filesystem

## Hardware Configuration

### SSD Setup
- **Device**: `/dev/nvme0n1` (932GB NVMe SSD)
- **Partition**: `/dev/nvme0n1p1` (single partition, full disk)
- **Filesystem**: XFS (optimized for large files and performance)
- **Mount Point**: `/mnt/shared`
- **Total Space**: 932GB
- **Available Space**: 914GB (18GB reserved for XFS metadata)

### Filesystem Details
```bash
# Check filesystem info
sudo xfs_info /mnt/shared

# Check disk usage
df -h /mnt/shared

# Check mount status
mount | grep /mnt/shared
```

## NFS Server Configuration

### Service Details
- **Service**: `nfs-kernel-server`
- **Port**: 2049 (NFS), 111 (RPC)
- **Protocol**: NFSv4 (with NFSv3 compatibility)
- **Export Path**: `/mnt/shared`

### Allowed Clients
The NFS server allows connections from all cluster nodes:
- 192.168.7.200 (master - self-mount capable)
- 192.168.7.201 (worker-1)
- 192.168.7.202 (worker-2)
- 192.168.7.203 (worker-3)

### Export Configuration
```bash
# /etc/exports content
/mnt/shared 192.168.7.200(rw,sync,no_subtree_check,no_root_squash)
/mnt/shared 192.168.7.201(rw,sync,no_subtree_check,no_root_squash)
/mnt/shared 192.168.7.202(rw,sync,no_subtree_check,no_root_squash)
/mnt/shared 192.168.7.203(rw,sync,no_subtree_check,no_root_squash)
```

### NFS Options Explained
- `rw`: Read-write access
- `sync`: Synchronous writes (data integrity)
- `no_subtree_check`: Improved performance
- `no_root_squash`: Root user access preserved

### NFS Client Usage

#### Mounting from Cluster Nodes
```bash
# Create mount point
sudo mkdir -p /mnt/cluster-shared

# Mount NFS share
sudo mount -t nfs 192.168.7.200:/mnt/shared /mnt/cluster-shared

# Verify mount
df -h /mnt/cluster-shared
ls -la /mnt/cluster-shared/
```

#### Persistent Mounting
Add to `/etc/fstab` on client nodes:
```bash
192.168.7.200:/mnt/shared /mnt/cluster-shared nfs defaults 0 0
```

#### Testing NFS
```bash
# List available exports
showmount -e 192.168.7.200

# Test write access
echo "NFS test" | sudo tee /mnt/cluster-shared/nfs-test.txt

# Verify from other nodes
cat /mnt/cluster-shared/nfs-test.txt
```

## Samba Server Configuration

### Service Details
- **Services**: `smbd` (file sharing), `nmbd` (NetBIOS)
- **Ports**: 445 (SMB), 139 (NetBIOS)
- **Share Name**: `shared`
- **Workgroup**: `WORKGROUP`

### Access Control
- **Network Access**: 192.168.0.0/16 (entire subnet)
- **Authentication**: Anonymous/Guest access enabled
- **Security**: `map to guest = bad user`

### Samba Configuration
```ini
# /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   server string = Cluster Shared Storage
   netbios name = MASTER
   security = user
   map to guest = bad user
   guest account = nobody
   
   # Network settings
   hosts allow = 192.168.0.0/16 127.0.0.1
   hosts deny = ALL
   
   # Performance and compatibility
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536
   use sendfile = yes

[shared]
   comment = Cluster Shared Storage
   path = /mnt/shared
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0775
   directory mask = 0775
   force user = nobody
   force group = nogroup
   public = yes
```

### Windows Client Access

#### File Explorer Access
1. Open Windows File Explorer
2. In the address bar, type: `\\192.168.7.200`
3. Press Enter
4. Access the `shared` folder
5. No authentication required (anonymous access)

#### Command Line Access
```cmd
# Map network drive
net use Z: \\192.168.7.200\shared

# List shares
net view \\192.168.7.200

# Disconnect drive
net use Z: /delete
```

### Linux Samba Client Access

#### Install CIFS Utils
```bash
# Ubuntu/Debian
sudo apt install cifs-utils

# RHEL/CentOS
sudo yum install cifs-utils
```

#### Mounting Samba Share
```bash
# Create mount point
sudo mkdir -p /mnt/samba-shared

# Mount with guest access
sudo mount -t cifs //192.168.7.200/shared /mnt/samba-shared -o guest,uid=1000,gid=1000

# Verify mount
df -h /mnt/samba-shared
```

#### Testing Samba
```bash
# List available shares
smbclient -L 192.168.7.200 -N

# Interactive access
smbclient //192.168.7.200/shared -N

# Test file operations
echo "Samba test" > /mnt/samba-shared/samba-test.txt
```

## Kubernetes Integration

### NFS StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-shared
provisioner: nfs.csi.k8s.io
parameters:
  server: 192.168.7.200
  share: /mnt/shared
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
  - hard
  - nfsvers=4.1
```

### PersistentVolume Example
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-shared-pv
spec:
  capacity:
    storage: 900Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.7.200
    path: /mnt/shared
  persistentVolumeReclaimPolicy: Retain
```

### PersistentVolumeClaim Example
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-shared
```

### Pod Usage Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-storage-test
spec:
  containers:
  - name: test-container
    image: busybox
    command: ['sh', '-c', 'echo "Hello from $(hostname)" > /shared/test-$(date +%s).txt && sleep 3600']
    volumeMounts:
    - name: shared-vol
      mountPath: /shared
  volumes:
  - name: shared-vol
    persistentVolumeClaim:
      claimName: shared-storage
```

## Performance Optimization

### XFS Filesystem Tuning
The XFS filesystem is configured with optimal settings:
- **Block size**: 4096 bytes
- **Allocation groups**: 4 (for parallel I/O)
- **Features enabled**: reflink, crc, finobt, rmapbt
- **Journal**: Internal log for consistency

### NFS Performance Tips
```bash
# Mount with performance options
sudo mount -t nfs 192.168.7.200:/mnt/shared /mnt/cluster-shared \
  -o rsize=1048576,wsize=1048576,hard,intr,timeo=600
```

### Samba Performance Tips
The configuration includes:
- `use sendfile = yes` - Kernel-level file transfers
- Large socket buffers for high throughput
- TCP_NODELAY for low latency

## Monitoring and Maintenance

### Check Service Status
```bash
# NFS services
sudo systemctl status nfs-kernel-server
sudo systemctl status rpcbind

# Samba services
sudo systemctl status smbd
sudo systemctl status nmbd
```

### Monitor Storage Usage
```bash
# Disk usage
df -h /mnt/shared

# Detailed usage by directory
sudo du -sh /mnt/shared/*

# Inode usage
df -i /mnt/shared
```

### Check Active Connections
```bash
# NFS connections
sudo ss -tn | grep :2049

# Samba connections
sudo ss -tn | grep -E ':(139|445)'
sudo smbstatus
```

### Log Files
```bash
# NFS logs
sudo journalctl -u nfs-kernel-server -f

# Samba logs
sudo tail -f /var/log/samba/log.smbd
sudo tail -f /var/log/samba/log.nmbd
```

## Backup and Recovery

### Backup Strategies
```bash
# Create snapshot (if supported)
sudo xfs_freeze -f /mnt/shared
# Perform backup
sudo xfs_freeze -u /mnt/shared

# Rsync backup
rsync -av --progress /mnt/shared/ /backup/location/

# Tar backup
sudo tar -czf /backup/shared-$(date +%Y%m%d).tar.gz -C /mnt shared/
```

### Recovery Procedures
```bash
# Check filesystem
sudo umount /mnt/shared
sudo xfs_repair /dev/nvme0n1p1
sudo mount /dev/nvme0n1p1 /mnt/shared

# Restore from backup
sudo rsync -av --progress /backup/location/ /mnt/shared/
```

## Security Considerations

### NFS Security
- Access restricted to cluster nodes only
- No anonymous access (unlike Samba)
- Root access preserved for administrative tasks

### Samba Security
- Network access limited to 192.168.0.0/16
- Anonymous access for convenience
- Consider adding authentication for production use

### Firewall Configuration
```bash
# Allow NFS (if firewall enabled)
sudo ufw allow from 192.168.7.0/24 to any port 2049
sudo ufw allow from 192.168.7.0/24 to any port 111

# Allow Samba (if firewall enabled)
sudo ufw allow from 192.168.0.0/16 to any port 445
sudo ufw allow from 192.168.0.0/16 to any port 139
```

## Troubleshooting

### Common NFS Issues
```bash
# Export not visible
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Permission denied
# Check export options and client IP
sudo exportfs -v

# Stale file handle
sudo umount /mnt/cluster-shared
sudo mount -t nfs 192.168.7.200:/mnt/shared /mnt/cluster-shared
```

### Common Samba Issues
```bash
# Test configuration
sudo testparm

# Restart services
sudo systemctl restart smbd nmbd

# Check share access
smbclient -L localhost -N

# Permission issues
sudo chown -R nobody:nogroup /mnt/shared
sudo chmod -R 775 /mnt/shared
```

### Network Connectivity
```bash
# Test NFS port
telnet 192.168.7.200 2049

# Test Samba ports
telnet 192.168.7.200 445
telnet 192.168.7.200 139

# Check listening services
sudo ss -tlnp | grep -E ':(2049|445|139|111)'
```

## Best Practices

1. **Regular Monitoring**: Check disk usage and service status regularly
2. **Backup Strategy**: Implement automated backups of critical data
3. **Performance Tuning**: Monitor I/O patterns and adjust mount options
4. **Security Updates**: Keep NFS and Samba packages updated
5. **Access Control**: Review and audit access permissions periodically
6. **Documentation**: Keep track of mounted clients and usage patterns

## Conclusion

This shared storage setup provides robust, high-performance storage for the cluster with dual-protocol access. The combination of NFS for Kubernetes/Linux workloads and Samba for Windows compatibility ensures maximum flexibility for diverse use cases.

For additional support and advanced configurations, refer to:
- [NFS-STORAGE-GUIDE.md](NFS-STORAGE-GUIDE.md) - Kubernetes-specific NFS setup
- [CLUSTER-INFO.md](CLUSTER-INFO.md) - Quick reference information
- Official documentation for [NFS](https://nfs.sourceforge.net/) and [Samba](https://www.samba.org/)
