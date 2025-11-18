#!/bin/bash
# Quick SSH helper for cluster nodes (physical machines)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/cluster-hosts.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/cluster-hosts.env"
fi

SSH_USER=${SSH_USER:-ubuntu}
SSH_KEY=${SSH_KEY:-}
SSH_EXTRA_OPTS=${SSH_EXTRA_OPTS:-}
MASTER_IP=${MASTER_IP:-192.168.7.200}
WORKER_IPS=${WORKER_IPS:-"192.168.7.201 192.168.7.202 192.168.7.203"}

read -r -a WORKER_IPS_ARR <<<"${WORKER_IPS}"

SSH_OPTS=("-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null")
if [ -n "${SSH_KEY}" ]; then
  SSH_OPTS+=("-i" "${SSH_KEY}")
fi
if [ -n "${SSH_EXTRA_OPTS}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARR=( ${SSH_EXTRA_OPTS} )
  SSH_OPTS+=("${EXTRA_ARR[@]}")
fi

case "$1" in
  master|m)
    exec ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}"
    ;;
  worker-1|worker1|w1)
    exec ssh "${SSH_OPTS[@]}" "${SSH_USER}@${WORKER_IPS_ARR[0]}"
    ;;
  worker-2|worker2|w2)
    exec ssh "${SSH_OPTS[@]}" "${SSH_USER}@${WORKER_IPS_ARR[1]}"
    ;;
  worker-3|worker3|w3)
    exec ssh "${SSH_OPTS[@]}" "${SSH_USER}@${WORKER_IPS_ARR[2]}"
    ;;
  *)
    echo "Usage: $0 {master|m|worker-1|w1|worker-2|w2|worker-3|w3}"
    echo ""
    echo "Examples:"
    echo "  $0 master     # SSH to master node"
    echo "  $0 worker-1   # SSH to worker-1"
    echo "  $0 w1         # SSH to worker-1 (short)"
    echo ""
    echo "Configure hosts in: ${SCRIPT_DIR}/cluster-hosts.env"
    exit 1
    ;;
esac

