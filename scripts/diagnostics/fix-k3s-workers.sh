#!/bin/bash
# Restart k3s-agent on worker nodes to fix NotReady (e.g. after "Kubelet stopped posting node status").
# Run from a machine that can SSH to the workers (e.g. your laptop or the master).

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/../cluster-hosts.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/../cluster-hosts.env"
fi

SSH_USER=${SSH_USER:-ubuntu}
SSH_KEY=${SSH_KEY:-}
SSH_EXTRA_OPTS=${SSH_EXTRA_OPTS:-}
WORKER_IPS=${WORKER_IPS:-"192.168.7.201 192.168.7.202 192.168.7.203"}

# Optional: only fix these workers (space-separated IPs). Empty = fix all.
FIX_IPS="${FIX_IPS:-192.168.7.201 192.168.7.203}"

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -o BatchMode=yes)
if [ -n "${SSH_KEY}" ]; then
  SSH_OPTS+=(-i "${SSH_KEY}")
fi
if [ -n "${SSH_EXTRA_OPTS}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARR=( ${SSH_EXTRA_OPTS} )
  SSH_OPTS+=("${EXTRA_ARR[@]}")
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  k3s Worker Nodes Fix (restart k3s-agent)                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

for ip in $FIX_IPS; do
  echo "--- $ip ---"
  # Use --no-block so systemctl returns immediately (agent can take a while to stop/start)
  if [ "${FORCE_RESTART:-0}" = "1" ]; then
    cmd="(sudo pkill -9 -f 'k3s agent' 2>/dev/null || true); sleep 2; sudo systemctl start k3s-agent --no-block; sleep 5; sudo systemctl is-active k3s-agent"
  else
    cmd="sudo systemctl restart k3s-agent --no-block; sleep 5; sudo systemctl is-active k3s-agent"
  fi
  if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${ip}" "$cmd"; then
    echo "  ✓ k3s-agent restarted and active"
  else
    echo "  ✗ Failed to restart or connect to $ip"
  fi
  echo ""
done

echo "Wait ~30–60s then check: export KUBECONFIG=~/.kube/config-homelabs && kubectl get nodes -o wide"
echo ""
echo "If script hangs or SSH fails:"
echo "  1. Ensure passwordless sudo for ${SSH_USER} on workers (e.g. ubuntu ALL=(ALL) NOPASSWD:ALL)."
echo "  2. Or log in to each worker (console/SSH) and run: sudo systemctl restart k3s-agent"
echo "  3. If 'restart' hangs (agent stuck), run on worker: sudo pkill -9 -f 'k3s agent'; sudo systemctl start k3s-agent"
echo ""
echo "If nodes stay NotReady after restart: workers cannot reach master API (192.168.7.200:6443)."
echo "  From each worker run: ping 192.168.7.200 && curl -k -s -o /dev/null -w '%{http_code}' --connect-timeout 3 https://192.168.7.200:6443/healthz"
echo "  Fix: firewall (allow 6443 and required ports between nodes), routing, or physical network."
