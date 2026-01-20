#!/bin/bash
# Diagnose why luismachadoreis.dev is not opening in browser

set -euo pipefail

NAMESPACE="luismachadoreis-dev"
DOMAIN="luismachadoreis.dev"
SERVICE_NAME="static-site"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  luismachadoreis.dev Diagnostic                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}1. Checking namespace...${NC}"
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} Namespace '$NAMESPACE' exists"
else
  echo -e "   ${RED}✗${NC} Namespace '$NAMESPACE' NOT found"
  echo "   Run: terraform apply"
  exit 1
fi

echo ""
echo -e "${BLUE}2. Checking deployment...${NC}"
DEPLOYMENT_NAME="luismachadoreis-dev"
if kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} Deployment '$DEPLOYMENT_NAME' exists"
  kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
  
  READY=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  DESIRED=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
  
  if [ "$READY" -eq "$DESIRED" ] && [ "$READY" -gt 0 ]; then
    echo -e "   ${GREEN}✓${NC} Deployment is ready ($READY/$DESIRED replicas)"
  else
    echo -e "   ${YELLOW}⚠${NC}  Deployment not ready ($READY/$DESIRED replicas)"
    echo ""
    echo "   Checking pod status..."
    kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev
  fi
else
  echo -e "   ${RED}✗${NC} Deployment '$DEPLOYMENT_NAME' NOT found"
  exit 1
fi

echo ""
echo -e "${BLUE}3. Checking pods...${NC}"
PODS=$(kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$PODS" -gt 0 ]; then
  echo -e "   ${GREEN}✓${NC} Found $PODS pod(s)"
  kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev -o wide
  
  FAILED_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "$FAILED_PODS" -gt 0 ]; then
    echo ""
    echo -e "   ${YELLOW}⚠${NC}  $FAILED_PODS pod(s) not running:"
    kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev --field-selector=status.phase!=Running
    echo ""
    echo "   Pod events:"
    for pod in $(kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev --field-selector=status.phase!=Running -o name); do
      echo "   --- $pod ---"
      kubectl describe "$pod" -n "$NAMESPACE" | grep -A 10 "Events:" || true
    done
  fi
else
  echo -e "   ${RED}✗${NC} No pods found"
fi

echo ""
echo -e "${BLUE}4. Checking service...${NC}"
if kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} Service '$SERVICE_NAME' exists"
  kubectl get service "$SERVICE_NAME" -n "$NAMESPACE"
  
  ENDPOINTS=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
  if [ -n "$ENDPOINTS" ]; then
    echo -e "   ${GREEN}✓${NC} Service has endpoints: $ENDPOINTS"
  else
    echo -e "   ${YELLOW}⚠${NC}  Service has NO endpoints (pods may not be ready)"
  fi
else
  echo -e "   ${RED}✗${NC} Service '$SERVICE_NAME' NOT found"
fi

echo ""
echo -e "${BLUE}5. Testing service internally...${NC}"
SERVICE_URL="http://${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:80"
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$POD_NAME" ]; then
  echo "   Testing from pod: $POD_NAME"
  if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- wget -q -O- --timeout=5 "$SERVICE_URL" &>/dev/null; then
    echo -e "   ${GREEN}✓${NC} Service is responding internally"
  else
    echo -e "   ${YELLOW}⚠${NC}  Service test failed (may be starting up)"
  fi
else
  echo -e "   ${YELLOW}⚠${NC}  No pods available for testing"
fi

echo ""
echo -e "${BLUE}6. Checking Cloudflare Tunnel...${NC}"
TUNNEL_NAMESPACE="cloudflare-tunnel"
if kubectl get namespace "$TUNNEL_NAMESPACE" &>/dev/null; then
  echo -e "   ${GREEN}✓${NC} Tunnel namespace exists"
  
  TUNNEL_PODS=$(kubectl get pods -n "$TUNNEL_NAMESPACE" -l app=cloudflare-tunnel --no-headers 2>/dev/null | grep -c Running || echo "0")
  if [ "$TUNNEL_PODS" -gt 0 ]; then
    echo -e "   ${GREEN}✓${NC} $TUNNEL_PODS tunnel pod(s) running"
    kubectl get pods -n "$TUNNEL_NAMESPACE" -l app=cloudflare-tunnel
  else
    echo -e "   ${RED}✗${NC} No tunnel pods running"
    echo "   Run: terraform apply (if tunnel not deployed)"
  fi
  
  echo ""
  echo "   Checking tunnel configuration for $DOMAIN..."
  if kubectl get configmap cloudflare-tunnel-config -n "$TUNNEL_NAMESPACE" &>/dev/null; then
    echo "   Tunnel ingress rules:"
    kubectl get configmap cloudflare-tunnel-config -n "$TUNNEL_NAMESPACE" -o jsonpath='{.data.config\.yaml}' | grep -A 2 "luismachadoreis.dev" || echo "   Rule not found in config"
  fi
else
  echo -e "   ${YELLOW}⚠${NC}  Tunnel namespace not found"
  echo "   Cloudflare Tunnel may not be deployed"
fi

echo ""
echo -e "${BLUE}7. Checking DNS resolution...${NC}"
if command -v dig &>/dev/null; then
  DNS_RESULT=$(dig +short "$DOMAIN" @1.1.1.1 2>/dev/null | head -1 || echo "")
  if [ -n "$DNS_RESULT" ]; then
    echo -e "   ${GREEN}✓${NC} DNS resolves to: $DNS_RESULT"
    if [[ "$DNS_RESULT" == *".cfargotunnel.com" ]]; then
      echo -e "   ${GREEN}✓${NC} DNS points to Cloudflare Tunnel (correct)"
    else
      echo -e "   ${YELLOW}⚠${NC}  DNS does NOT point to Cloudflare Tunnel"
      echo "   Expected: *.cfargotunnel.com"
      echo "   Configure DNS in Cloudflare dashboard:"
      echo "   - Type: CNAME"
      echo "   - Name: @ (or $DOMAIN)"
      echo "   - Content: <tunnel-uuid>.cfargotunnel.com"
      echo "   - Proxy: Yes (orange cloud)"
    fi
  else
    echo -e "   ${RED}✗${NC} DNS does not resolve"
    echo "   Configure DNS in Cloudflare dashboard"
  fi
else
  echo "   dig not available, skipping DNS check"
fi

echo ""
echo -e "${BLUE}8. Testing domain connectivity...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://$DOMAIN" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
  echo -e "   ${GREEN}✓${NC} Domain is accessible (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "000" ]; then
  echo -e "   ${RED}✗${NC} Domain is NOT accessible (connection failed)"
  echo "   Possible causes:"
  echo "   - DNS not configured"
  echo "   - Cloudflare Tunnel not running"
  echo "   - Service not responding"
else
  echo -e "   ${YELLOW}⚠${NC}  Domain returned HTTP $HTTP_CODE"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Quick Fixes                                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "If deployment/pods are not ready:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  kubectl logs <pod-name> -n $NAMESPACE"
echo ""
echo "If service has no endpoints:"
echo "  kubectl get endpoints $SERVICE_NAME -n $NAMESPACE"
echo "  kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
echo ""
echo "If Cloudflare Tunnel is not working:"
echo "  kubectl get pods -n $TUNNEL_NAMESPACE"
echo "  kubectl logs -n $TUNNEL_NAMESPACE -l app=cloudflare-tunnel"
echo ""
echo "If DNS is not configured:"
echo "  1. Get tunnel UUID from Cloudflare Zero Trust dashboard"
echo "  2. Create CNAME record: @ -> <tunnel-uuid>.cfargotunnel.com"
echo "  3. Enable proxy (orange cloud) in Cloudflare"
echo ""
