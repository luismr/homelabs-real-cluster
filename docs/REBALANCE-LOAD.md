# Force Kubernetes to balance load across all nodes

Use these methods to spread pods across master and workers (master, worker-1, worker-2, worker-3).

---

## 1. Trigger the descheduler now (recommended)

The cluster already runs the **Kubernetes Descheduler** as a CronJob every 30 minutes. To rebalance immediately without waiting:

```bash
export KUBECONFIG=~/.kube/config-homelabs

# Create a one-off job from the CronJob
kubectl create job --from=cronjob/descheduler descheduler-manual-$(date +%s) -n kube-system

# Wait for it to finish (evictions then reschedule)
kubectl wait --for=condition=complete --timeout=120s job -l app=descheduler -n kube-system --all 2>/dev/null || true

# Check distribution
kubectl get pods -A -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --no-headers | awk '{c[$2]++} END{for(n in c) printf "  %-12s: %3d pods\n", n, c[n]}' | sort
kubectl top nodes --sort-by=memory
```

Or use the **one-command** script (no interaction):

```bash
./scripts/infrastructure/rebalance-now.sh
```

Or the interactive helper:

```bash
./scripts/infrastructure/descheduler-helper.sh
# Choose option 1 to trigger now, then option 4 to see distribution
```

**What the descheduler does:** It **evicts** pods that violate its policy (e.g. too many on one node, or duplicate replicas on the same node). The normal scheduler then reschedules them; with no affinity forcing them back, they can land on other nodes.

---

## 2. Descheduler policy (already configured)

Current policy in `kube-system` ConfigMap `descheduler`:

| Strategy | Purpose |
|----------|--------|
| **LowNodeUtilization** | Move pods off nodes above 50% CPU/memory/pods to nodes below 20% (balance load). |
| **RemoveDuplicates** | Evict duplicate replicas of the same ReplicaSet from the same node (spread replicas). |
| **RemovePodsViolatingTopologySpreadConstraint** | Enforce topology spread if you add constraints. |

To make rebalancing more aggressive you can lower the thresholds (so “underutilized” is easier to hit). Edit the policy and restart:

```bash
kubectl edit configmap descheduler -n kube-system
# In policy.yaml, under LowNodeUtilization params, e.g.:
#   targetThresholds: { cpu: 40, memory: 40, pods: 40 }
#   thresholds:       { cpu: 15, memory: 15, pods: 15 }
# Then delete the last descheduler job pod so the next CronJob run uses new config (or trigger a new job).
```

---

## 3. Manual rebalance (cordon + evict)

If you want to clear a specific node and let the scheduler spread pods elsewhere:

```bash
export KUBECONFIG=~/.kube/config-homelabs

# Example: rebalance away from master
kubectl cordon master
kubectl get pods -A -o wide --field-selector spec.nodeName=master

# Evict all evictable pods from master (Deployments/StatefulSets will recreate on other nodes)
kubectl drain master --ignore-daemonsets --delete-emptydir-data --force --grace-period=60

# When done, allow scheduling again
kubectl uncordon master
```

Use the same pattern for `worker-1`, `worker-2`, or `worker-3`. **Warning:** DaemonSets stay; pods without a controller (e.g. one-off Pods) are gone. Prefer triggering the descheduler unless you need to target one node.

---

## 4. Spread new pods (topology spread constraints)

To keep **future** deployments spread across nodes, add a topology spread constraint. Example for a Deployment:

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: my-app
```

- **topologyKey: kubernetes.io/hostname** = one domain per node (spread across all nodes).
- **maxSkew: 1** = limit imbalance between the most and least loaded node.
- **whenUnsatisfiable: ScheduleAnyway** = prefer spread but don’t block scheduling (use **DoNotSchedule** to enforce hard spread).

This doesn’t move existing pods; combine with the descheduler (or drain) for current load.

---

## 5. Quick reference

| Goal | Command / action |
|------|-------------------|
| Rebalance now | `./scripts/infrastructure/rebalance-now.sh` or create job from cronjob (see section 1) |
| Pod count per node | `kubectl get pods -A -o custom-columns=NODE:.spec.nodeName --no-headers \| sort \| uniq -c` |
| Node usage | `kubectl top nodes --sort-by=memory` |
| Descheduler schedule | CronJob runs every 30 min (`*/30 * * * *`) |
| Helper script | `./scripts/infrastructure/descheduler-helper.sh` |

All `kubectl` commands assume:

```bash
export KUBECONFIG=~/.kube/config-homelabs
```
