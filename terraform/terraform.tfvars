# Terraform Variables
# This file is gitignored for security
#
# Sensitive values are read from environment variables:
#   - CLOUDFLARE_TUNNEL_TOKEN -> TF_VAR_cloudflare_tunnel_token
#   - GITHUB_USER -> TF_VAR_ghcr_username
#   - GITHUB_TOKEN -> TF_VAR_ghcr_token
#
# Set them before running terraform:
#   export TF_VAR_cloudflare_tunnel_token="$CLOUDFLARE_TUNNEL_TOKEN"
#   export TF_VAR_ghcr_username="$GITHUB_USER"
#   export TF_VAR_ghcr_token="$GITHUB_TOKEN"

# Cloudflare Tunnel Token (optional - get from https://one.dash.cloudflare.com/)
# Leave empty to deploy sites without tunnel initially
# Set via: export TF_VAR_cloudflare_tunnel_token="$CLOUDFLARE_TUNNEL_TOKEN"
# cloudflare_tunnel_token = ""  # Commented out - use TF_VAR_cloudflare_tunnel_token env var instead

# NFS Storage Configuration
enable_nfs_storage = false
storage_class      = "nfs-client"

# Docker Images for Static Sites (replace with your actual images)
pudim_site_image           = "ghcr.io/luismr/pudim-dev-calculator:main-5b33b7d"  # Replace with your pudim.dev image
luismachadoreis_site_image = "ghcr.io/luismr/luismachadoreis-dev-portfolio:main-ebd37e5"  # Replace with your luismachadoreis.dev image
carimbo_site_image         = "ghcr.io/luismr/carimbo-vip-site:sha-fb3b13a"  # Replace with your carimbo.vip image

# GitHub Container Registry (GHCR) Authentication (for private images)
# Leave empty if using public images
# Set via: export TF_VAR_ghcr_username="$GITHUB_USER"
# Set via: export TF_VAR_ghcr_token="$GITHUB_TOKEN"
# ghcr_username = null  # Commented out - use TF_VAR_ghcr_username env var instead
# ghcr_token    = null  # Commented out - use TF_VAR_ghcr_token env var instead
