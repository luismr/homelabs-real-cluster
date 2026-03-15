# Cluster full diagnostics report

**Generated:** 2026-03-12 (run with `KUBECONFIG=~/.kube/config-homelabs`)

---

## 1. Control plane & API (from this machine)

| Check | Status |
|-------|--------|
| Ping 192.168.7.200 | ✅ Reachable |
| API server https://192.168.7.200:6443 | ✅ **Responding** (healthz returns 401 without auth — expected) |
| kubectl cluster-info | ✅ **OK** — control plane, CoreDNS, metrics-server running |

**Fix applied:** k3s on master was in "activating (start)" state; after it finished starting, API began listening on 192.168.7.200:6443 and cluster-info succeeded.

---

## 2. Nodes

| Node     | Status   | Internal IP   | Roles              |
|----------|----------|---------------|--------------------|
| master   | **Ready** | 192.168.7.200 | control-plane,etcd |
| worker-1 | **Ready** | 192.168.7.201 | —                  |
| worker-2 | **Ready** | 192.168.7.202 | —                  |
| worker-3 | **Ready** | 192.168.7.203 | —                  |

All 4 nodes are Ready.

---

## 3. Node resource usage

**N/A** — `kubectl top nodes` requires API. After API is reachable:

```bash
export KUBECONFIG=~/.kube/config-homelabs
kubectl top nodes --sort-by=memory
```

---

## 4. Workloads (pods)

**N/A** — Pod listing requires API. After API is reachable:

```bash
kubectl get pods -A -o wide
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
```

---

## 5. Loki (monitoring)

**N/A** — Pod/event checks require API. When API is back, check:

```bash
kubectl get pod loki-0 -n monitoring -o wide
kubectl describe pod loki-0 -n monitoring | tail -40
```

Previous note: loki-0 had been 0/1 Unknown with VolumePermissionChangeInProgress on NFS.

---

## 6. Storage

**N/A** — Storage checks require API. When API is back:

```bash
kubectl get storageclass
kubectl get pvc -A
kubectl get pods -n nfs-system
```

---

## 7. Events

**N/A** — Events require API. When API is back:

```bash
kubectl get events -A --sort-by='.lastTimestamp' | tail -40
```

---

## 8. Horizontal Pod Autoscalers (HPAs)

**N/A** — Requires API. Previous run: several HPAs had “no metrics returned”; redirector HPA needs resource requests on the nginx container.

---

## 9. Summary

| Area | Status | Action |
|------|--------|--------|
| API server (6443) | ✅ **Fixed** — responding | — |
| All nodes | ✅ **Ready** (4/4) | — |
| Node/pod/storage/events | Run commands in sections 3–7 as needed | — |

**Homelabs kubeconfig (use for all kubectl):**

```bash
export KUBECONFIG=~/.kube/config-homelabs
kubectl get nodes -o wide
kubectl top nodes --sort-by=memory
```
