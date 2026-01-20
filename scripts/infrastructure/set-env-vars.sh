#!/bin/bash
# Helper script to set Terraform variables from environment variables
# Usage: source set-env-vars.sh

# Map environment variables to Terraform variables
# Handle both CLOUDFLARE_TUNNEL_TOKEN (correct) and CLOUDFARE_TUNNEL_TOKEN (typo)
if [ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
  export TF_VAR_cloudflare_tunnel_token="$CLOUDFLARE_TUNNEL_TOKEN"
elif [ -n "$CLOUDFARE_TUNNEL_TOKEN" ]; then
  # Handle typo in env var name (missing 'L')
  export TF_VAR_cloudflare_tunnel_token="$CLOUDFARE_TUNNEL_TOKEN"
  echo "Warning: Using CLOUDFARE_TUNNEL_TOKEN (typo detected). Please use CLOUDFLARE_TUNNEL_TOKEN instead."
fi

if [ -n "$GITHUB_USER" ]; then
  export TF_VAR_ghcr_username="$GITHUB_USER"
fi

if [ -n "$GITHUB_TOKEN" ]; then
  export TF_VAR_ghcr_token="$GITHUB_TOKEN"
fi

echo "Terraform environment variables set from:"
echo "  CLOUDFLARE_TUNNEL_TOKEN -> TF_VAR_cloudflare_tunnel_token"
echo "  GITHUB_USER -> TF_VAR_ghcr_username"
echo "  GITHUB_TOKEN -> TF_VAR_ghcr_token"

