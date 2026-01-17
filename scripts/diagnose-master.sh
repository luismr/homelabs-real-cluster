#!/bin/bash
# Diagnose why Kubernetes cluster is not online
# Connects to master node and checks k3s status

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/cluster-hosts.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/cluster-hosts.env"
fi

SSH_USER=${SSH_USER:-ubuntu}
SSH_KEY=${SSH_KEY:-}
SSH_EXTRA_OPTS=${SSH_EXTRA_OPTS:-}
MASTER_IP=${MASTER_IP:-192.168.7.200}

SSH_OPTS=("-o" "StrictHostKeyChecking=no" "-o" "UserKnownHostsFile=/dev/null" "-o" "ConnectTimeout=10")
if [ -n "${SSH_KEY}" ]; then
  SSH_OPTS+=("-i" "${SSH_KEY}")
fi
if [ -n "${SSH_EXTRA_OPTS}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARR=( ${SSH_EXTRA_OPTS} )
  SSH_OPTS+=("${EXTRA_ARR[@]}")
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Kubernetes Master Node Diagnostic                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Connecting to master node: ${SSH_USER}@${MASTER_IP}"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test SSH connectivity first
echo -e "${BLUE}1. Testing SSH connectivity...${NC}"
if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" "echo 'SSH connection successful'" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} SSH connection successful"
else
  echo -e "   ${RED}✗${NC} Cannot connect to master node via SSH"
  echo ""
  echo "   Troubleshooting:"
  echo "   - Check if master node is powered on"
  echo "   - Check network connectivity: ping ${MASTER_IP}"
  echo "   - Verify SSH service is running on master"
  echo "   - Check SSH key configuration in cluster-hosts.env"
  exit 1
fi

echo ""
echo -e "${BLUE}2. Checking k3s service status...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  echo "   k3s service status:"
  sudo systemctl status k3s --no-pager -l | head -20 || echo "   ⚠️  k3s service not found or not running"
  
  echo ""
  echo "   k3s service enabled:"
  if sudo systemctl is-enabled k3s &>/dev/null; then
    echo "   ✓ k3s is enabled (will start on boot)"
  else
    echo "   ⚠️  k3s is NOT enabled (will not start on boot)"
  fi
  
  echo ""
  echo "   k3s service active:"
  if sudo systemctl is-active k3s &>/dev/null; then
    echo "   ✓ k3s is active (running)"
  else
    echo "   ✗ k3s is NOT active (not running)"
  fi
EOF

echo ""
echo -e "${BLUE}3. Checking system resources...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  echo "   Memory usage:"
  free -h | grep -E "Mem|Swap" | awk '{print "   " $1 ": " $3 "/" $2 " (" $5 ")"}'
  
  echo ""
  echo "   Disk usage:"
  df -h / | tail -1 | awk '{print "   Root: " $3 "/" $2 " (" $5 " used)"}'
  df -h /var/lib/rancher/k3s 2>/dev/null | tail -1 | awk '{print "   k3s data: " $3 "/" $2 " (" $5 " used)"}' || echo "   k3s data: N/A"
  
  echo ""
  echo "   CPU load:"
  uptime | awk -F'load average:' '{print "   " $2}'
  
  echo ""
  echo "   System uptime:"
  uptime -p
EOF

echo ""
echo -e "${BLUE}4. Checking k3s process...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  if pgrep -x k3s > /dev/null; then
    echo "   ✓ k3s process is running"
    echo "   Process details:"
    ps aux | grep '[k]3s server' | head -1 | awk '{print "   PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%"}'
  else
    echo "   ✗ k3s process is NOT running"
  fi
EOF

echo ""
echo -e "${BLUE}5. Checking k3s logs (last 30 lines)...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  echo "   Recent k3s journal logs:"
  sudo journalctl -u k3s -n 30 --no-pager | tail -30 || echo "   ⚠️  Could not retrieve logs"
EOF

echo ""
echo -e "${BLUE}6. Checking network connectivity...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  echo "   API server port (6443):"
  if sudo netstat -tlnp 2>/dev/null | grep -q ':6443' || sudo ss -tlnp 2>/dev/null | grep -q ':6443'; then
    echo "   ✓ Port 6443 is listening"
    sudo ss -tlnp 2>/dev/null | grep ':6443' || sudo netstat -tlnp 2>/dev/null | grep ':6443'
  else
    echo "   ✗ Port 6443 is NOT listening (API server not accessible)"
  fi
  
  echo ""
  echo "   k3s agent port (10250):"
  if sudo netstat -tlnp 2>/dev/null | grep -q ':10250' || sudo ss -tlnp 2>/dev/null | grep -q ':10250'; then
    echo "   ✓ Port 10250 is listening"
  else
    echo "   ⚠️  Port 10250 is NOT listening"
  fi
EOF

echo ""
echo -e "${BLUE}7. Checking k3s configuration...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo "   ✓ k3s config file exists"
    echo "   Config location: /etc/rancher/k3s/k3s.yaml"
  else
    echo "   ✗ k3s config file NOT found"
  fi
  
  if [ -d /var/lib/rancher/k3s ]; then
    echo "   ✓ k3s data directory exists"
    echo "   Data directory size:"
    sudo du -sh /var/lib/rancher/k3s 2>/dev/null || echo "   ⚠️  Cannot read data directory"
  else
    echo "   ✗ k3s data directory NOT found"
  fi
EOF

echo ""
echo -e "${BLUE}8. Checking for common issues...${NC}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  echo "   Checking for disk space issues:"
  DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
  if [ "$DISK_USAGE" -gt 90 ]; then
    echo "   ⚠️  WARNING: Disk usage is ${DISK_USAGE}% (may cause issues)"
  else
    echo "   ✓ Disk usage is ${DISK_USAGE}% (OK)"
  fi
  
  echo ""
  echo "   Checking for memory issues:"
  MEM_AVAIL=$(free | grep Mem | awk '{printf "%.0f", $7/$2 * 100}')
  if [ "$MEM_AVAIL" -lt 10 ]; then
    echo "   ⚠️  WARNING: Only ${MEM_AVAIL}% memory available"
  else
    echo "   ✓ ${MEM_AVAIL}% memory available (OK)"
  fi
  
  echo ""
  echo "   Checking for systemd service errors:"
  if sudo systemctl status k3s &>/dev/null; then
    FAILED_COUNT=$(sudo systemctl list-failed | grep -c k3s || echo "0")
    if [ "$FAILED_COUNT" -gt 0 ]; then
      echo "   ⚠️  k3s service has failed states"
    else
      echo "   ✓ No failed service states"
    fi
  fi
EOF

echo ""
echo -e "${BLUE}9. Testing API server connectivity...${NC}"
if curl -k -s --connect-timeout 5 "https://${MASTER_IP}:6443/healthz" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} API server is responding"
else
  echo -e "   ${RED}✗${NC} API server is NOT responding"
  echo ""
  echo "   This means:"
  echo "   - k3s service may not be running"
  echo "   - API server may not have started"
  echo "   - Network/firewall may be blocking port 6443"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Recommended Actions                                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if k3s is running and provide recommendations
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_IP}" << 'EOF'
  if ! sudo systemctl is-active k3s &>/dev/null; then
    echo "k3s is NOT running. Try these commands on the master node:"
    echo ""
    echo "1. Start k3s service:"
    echo "   sudo systemctl start k3s"
    echo ""
    echo "2. Check why it failed to start:"
    echo "   sudo journalctl -u k3s -n 50 --no-pager"
    echo ""
    echo "3. If k3s won't start, check for errors:"
    echo "   sudo systemctl status k3s -l"
    echo ""
    echo "4. Enable k3s to start on boot:"
    echo "   sudo systemctl enable k3s"
    echo ""
    echo "5. If all else fails, restart the master node:"
    echo "   sudo reboot"
  else
    echo "k3s service is running. If API server is still not accessible:"
    echo ""
    echo "1. Wait a few minutes for API server to fully start"
    echo "2. Check API server logs:"
    echo "   sudo journalctl -u k3s -n 100 --no-pager | grep -i api"
    echo ""
    echo "3. Restart k3s service:"
    echo "   sudo systemctl restart k3s"
    echo ""
    echo "4. Check if port 6443 is accessible:"
    echo "   sudo ss -tlnp | grep 6443"
  fi
EOF

echo ""
echo "To connect to master node and run commands manually:"
echo "  ./scripts/ssh-nodes.sh master"
echo "  # or"
echo "  ssh ${SSH_USER}@${MASTER_IP}"
