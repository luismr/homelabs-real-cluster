#!/bin/bash
# Quick check script for luismachadoreis.dev

NAMESPACE="luismachadoreis-dev"
DOMAIN="luismachadoreis.dev"

echo "Quick status check for $DOMAIN"
echo "================================"
echo ""

echo "1. Namespace:"
kubectl get namespace "$NAMESPACE" 2>/dev/null || echo "   ✗ Not found"

echo ""
echo "2. Deployment:"
kubectl get deployment luismachadoreis-dev -n "$NAMESPACE" 2>/dev/null || echo "   ✗ Not found"

echo ""
echo "3. Pods:"
kubectl get pods -n "$NAMESPACE" -l app=luismachadoreis-dev 2>/dev/null || echo "   ✗ No pods found"

echo ""
echo "4. Service:"
kubectl get service static-site -n "$NAMESPACE" 2>/dev/null || echo "   ✗ Not found"

echo ""
echo "5. Cloudflare Tunnel:"
kubectl get pods -n cloudflare-tunnel -l app=cloudflare-tunnel 2>/dev/null || echo "   ✗ Tunnel not found"

echo ""
echo "6. DNS:"
dig +short "$DOMAIN" @1.1.1.1 2>/dev/null || echo "   ✗ DNS not resolving"

echo ""
echo "For detailed diagnostics, run: ./diagnose-luismachadoreis-dev.sh"
