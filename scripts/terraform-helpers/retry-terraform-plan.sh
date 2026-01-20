#!/bin/bash
# Retry Terraform plan with better error handling

set -e

echo "=== Running Terraform Plan ==="
echo "This may take a few minutes..."

# Retry logic for network issues
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if terraform plan "$@"; then
    echo ""
    echo "✅ Terraform plan completed successfully!"
    exit 0
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo ""
      echo "⚠️  Plan failed (attempt $RETRY_COUNT/$MAX_RETRIES)"
      echo "Retrying in 5 seconds..."
      sleep 5
    else
      echo ""
      echo "❌ Terraform plan failed after $MAX_RETRIES attempts"
      echo ""
      echo "Common issues:"
      echo "1. Network connectivity to Kubernetes API server"
      echo "2. Kubernetes API server may be temporarily unavailable"
      echo "3. Check: kubectl cluster-info"
      exit 1
    fi
  fi
done
