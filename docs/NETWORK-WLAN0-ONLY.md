# Cluster: Only wlan0 for Network Connectivity

Cluster nodes must use **only wlan0** for connectivity so that cluster traffic (192.168.7.0/24) and the default route use the same interface. If another interface (e.g. `enP4p65s0`) is up with a different subnet and its own default route, nodes can fail to reach each other (e.g. workers cannot reach master 192.168.7.200).

## What the script does

On each node (master and workers), run:

```bash
sudo ./scripts/network/ensure-wlan0-only.sh
```

Or copy the script to the node and run it there:

```bash
# From your laptop (copy script then run on each node)
for ip in 192.168.7.200 192.168.7.201 192.168.7.202 192.168.7.203; do
  scp scripts/network/ensure-wlan0-only.sh ubuntu@$ip:/tmp/
  ssh ubuntu@$ip "sudo bash /tmp/ensure-wlan0-only.sh"
done
```

The script:

1. **Installs `net-tools`** if missing (so `route -n` works when verifying).
2. **Disables other interfaces** (e.g. `enP4p65s0`): adds a netplan file so they get no DHCP and no address, then brings the link down.
3. **Installs a systemd service** `cluster-wlan0-only.service` so those interfaces stay down after reboot.

It does **not** configure wlan0 itself. You must ensure 192.168.7.x is assigned on wlan0 (see below).

## Configure wlan0 with cluster IP (192.168.7.x)

Each node must have its cluster IP on **wlan0**:

- **master**: 192.168.7.200/24  
- **worker-1**: 192.168.7.201/24  
- **worker-2**: 192.168.7.202/24  
- **worker-3**: 192.168.7.203/24  

Gateway is often 192.168.7.1; if your WiFi uses another subnet (e.g. 192.168.4.1), use that as `gateway4` and ensure all cluster nodes are on the same L2/VLAN so 192.168.7.x is reachable between them.

### Option A: Netplan with WiFi (static IP on wlan0)

On each node, create or edit `/etc/netplan/00-wlan0-cluster.yaml` (adjust SSID and password):

```yaml
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.7.200/24   # Use .201, .202, .203 on workers
      gateway4: 192.168.7.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      access-points:
        "YOUR_WIFI_SSID":
          password: "YOUR_WIFI_PASSWORD"
```

Then:

```bash
sudo netplan apply
```

### Option B: wlan0 already gets IP via DHCP

If wlan0 gets an IP via DHCP from your router and the router uses 192.168.7.0/24, ensure the router hands out 192.168.7.200–203 (reserved/static) to each node’s wlan0. Then run only `ensure-wlan0-only.sh` so the other interface does not get an address or default route.

## Verify

On each node after applying:

```bash
ip -br a
route -n
```

You should see:

- **wlan0** with 192.168.7.xxx/24 and the only default route (e.g. via 192.168.7.1).
- No address and no default route on enP4p65s0 (or other ethernet); link should be DOWN.

From worker-1:

```bash
ping -c 1 192.168.7.200
curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 3 https://192.168.7.200:6443/healthz
```

Both should succeed so k3s-agent can reach the master.

## Custom interface list

To disable interfaces other than the default `enP4p65s0`:

```bash
sudo EXTRA_INTERFACES="enP4p65s0,eth0" ./scripts/network/ensure-wlan0-only.sh
```

## Reference: your routing table (worker-1 before fix)

Before applying the fix, worker-1 had two default routes and no explicit 192.168.7.0/24 route:

```
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.4.1     0.0.0.0         UG    0      0        0 wlan0
0.0.0.0         192.168.4.1     0.0.0.0         UG    100    0        0 enP4p65s0
192.168.0.0     0.0.0.0         255.255.0.0     U     0      0        0 wlan0
192.168.4.0     0.0.0.0         255.255.252.0   U     100    0        0 enP4p65s0
```

After ensuring only wlan0 is active and 192.168.7.x is on wlan0, cluster traffic and the default route use wlan0 only.
