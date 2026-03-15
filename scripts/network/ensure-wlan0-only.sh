#!/bin/bash
# Ensure only wlan0 is used for network connectivity on cluster nodes.
# Disables other interfaces (e.g. enP4p65s0) so they get no address and no default route.
# Cluster IPs (192.168.7.200-203) must be configured on wlan0 on each node (do that separately in netplan).
#
# Usage (run on each node with sudo):
#   sudo ./ensure-wlan0-only.sh
# Optional: comma-separated list of interfaces to disable (default: enP4p65s0)
#   sudo EXTRA_INTERFACES="enP4p65s0,eth0" ./ensure-wlan0-only.sh

set -euo pipefail

# Ensure net-tools is installed so 'route -n' works (Ubuntu/Debian)
if ! command -v route &>/dev/null; then
  echo "Installing net-tools (required for 'route' command)..."
  apt-get update -qq && apt-get install -y net-tools
fi

WLAN_IF="${WLAN_IF:-wlan0}"
NETPLAN_DIR="/etc/netplan"
# Interfaces to disable: no DHCP, no address, bring link down (comma or space separated)
EXTRA_INTERFACES="${EXTRA_INTERFACES:-enP4p65s0}"
# Convert to space-separated
EXTRA_INTERFACES="${EXTRA_INTERFACES//,/ }"

# All physical interfaces except wlan0 and loopback
get_other_interfaces() {
  for f in /sys/class/net/*; do
    [ -d "$f" ] || continue
    iface=$(basename "$f")
    [ "$iface" = "lo" ] && continue
    [ "$iface" = "${WLAN_IF}" ] && continue
    # Skip bridges and virtual
    [ -L "$f/bridge" ] 2>/dev/null && continue
    [ -d "$f/device" ] || [ -d "$f/wireless" ] || continue
    echo "$iface"
  done
}

DISABLE_LIST=""
for if in ${EXTRA_INTERFACES}; do
  [ -d "/sys/class/net/${if}" ] && DISABLE_LIST="${DISABLE_LIST} ${if}"
done
# If none from env, disable all physical non-wlan0
if [ -z "${DISABLE_LIST}" ]; then
  DISABLE_LIST=$(get_other_interfaces)
fi

echo "Keeping only ${WLAN_IF} active. Disabling (no address, link down):${DISABLE_LIST:- (none)}"

# Netplan: make these interfaces optional, no DHCP, no address — so they don't get a default route
if [ -n "${DISABLE_LIST}" ]; then
  NETPLAN_FILE="${NETPLAN_DIR}/01-cluster-disable-other-interfaces.yaml"
  mkdir -p "${NETPLAN_DIR}"
  cat > "${NETPLAN_FILE}.tmp" << 'NETPLAN_HEAD'
# Cluster: only wlan0 for connectivity. Other interfaces get no address and no default route.
network:
  version: 2
  ethernets:
NETPLAN_HEAD
  for if in ${DISABLE_LIST}; do
    cat >> "${NETPLAN_FILE}.tmp" << EOF
    ${if}:
      optional: true
      dhcp4: false
      dhcp6: false
EOF
  done
  mv "${NETPLAN_FILE}.tmp" "${NETPLAN_FILE}"
  chmod 600 "${NETPLAN_FILE}"
  echo "Applied ${NETPLAN_FILE}"
  netplan apply
fi

# Bring down the interfaces so they are not used
for if in ${DISABLE_LIST}; do
  [ -d "/sys/class/net/${if}" ] || continue
  ip link set "${if}" down 2>/dev/null && echo "  Down: ${if}" || true
done

# Install a small systemd service to re-apply "down" at boot (in case something brings them up)
if [ -n "${DISABLE_LIST}" ]; then
  SVC_NAME="cluster-wlan0-only.service"
  SVC_FILE="/etc/systemd/system/${SVC_NAME}"
  # Build ExecStart with actual interface list
  EXEC_START="/bin/sh -c '"
  for if in ${DISABLE_LIST}; do
    EXEC_START="${EXEC_START}[ -d /sys/class/net/${if} ] && ip link set ${if} down; "
  done
  EXEC_START="${EXEC_START}true'"
  cat > "${SVC_FILE}.tmp" << SVC
[Unit]
Description=Keep only wlan0 up for cluster (disable other interfaces)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${EXEC_START}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVC
  mv "${SVC_FILE}.tmp" "${SVC_FILE}"
  systemctl daemon-reload
  systemctl enable --now "${SVC_NAME}" 2>/dev/null || true
  echo "Enabled ${SVC_NAME} to keep interfaces down at boot"
fi

echo "Done. Verify: ip -br a; route -n"
ip -br a
echo "---"
route -n
