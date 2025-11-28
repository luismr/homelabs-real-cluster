# Terraform Variables
# This file is gitignored for security
#
# Sensitive values are read from environment variables:
#   - CLOUDFLARE_TUNNEL_TOKEN -> TF_VAR_cloudflare_tunnel_token
#   - GITHUB_USER -> TF_VAR_ghcr_username
#   - GITHUB_TOKEN -> TF_VAR_ghcr_token
#   - WAHA_API_KEY -> TF_VAR_carimbo_waha_api_key
#   - WAHA_DASHBOARD_PASSWORD -> TF_VAR_carimbo_waha_dashboard_password
#   - WAHA_SWAGGER_PASSWORD -> TF_VAR_carimbo_waha_swagger_password
#   - POSTGRES_PASSWORD -> TF_VAR_carimbo_postgres_password
#
# Set them before running terraform:
#   export TF_VAR_cloudflare_tunnel_token="$CLOUDFLARE_TUNNEL_TOKEN"
#   export TF_VAR_ghcr_username="$GITHUB_USER"
#   export TF_VAR_ghcr_token="$GITHUB_TOKEN"
#   export TF_VAR_carimbo_waha_api_key="$WAHA_API_KEY"
#   export TF_VAR_carimbo_waha_dashboard_username="$WAHA_DASHBOARD_USERNAME"
#   export TF_VAR_carimbo_waha_dashboard_password="$WAHA_DASHBOARD_PASSWORD"
#   export TF_VAR_carimbo_waha_swagger_username="$WAHA_SWAGGER_USERNAME"
#   export TF_VAR_carimbo_waha_swagger_password="$WAHA_SWAGGER_PASSWORD"
#   export TF_VAR_carimbo_postgres_password="$POSTGRES_PASSWORD"

# Cloudflare Tunnel Token (optional - get from https://one.dash.cloudflare.com/)
# Leave empty to deploy sites without tunnel initially
# Set via: export TF_VAR_cloudflare_tunnel_token="$CLOUDFLARE_TUNNEL_TOKEN"
# cloudflare_tunnel_token = ""  # Commented out - use TF_VAR_cloudflare_tunnel_token env var instead

# NFS Storage Configuration
enable_nfs_storage = true
storage_class      = "nfs-loki"

# Docker Images for Static Sites (replace with your actual images)
pudim_site_image           = "ghcr.io/luismr/pudim-dev-calculator:main-5b33b7d"          # Replace with your pudim.dev image
luismachadoreis_site_image = "ghcr.io/luismr/luismachadoreis-dev-portfolio:main-ebd37e5" # Replace with your luismachadoreis.dev image
carimbo_site_image         = "ghcr.io/luismr/carimbo-vip-site:sha-72d673b"               # Replace with your carimbo.vip image
carimbo_forms_image        = "ghcr.io/luismr/carimbo-vip-forms:main-41890ec"             # Replace with your carimbo.vip forms image
carimbo_waha_image         = "devlikeapro/waha:arm"                                      # WAHA (WhatsApp HTTP API) image - ARM64 version
carimbo_n8n_image          = "docker.n8n.io/n8nio/n8n"                                  # n8n workflow automation image
singularideas_site_image   = null                                                        # Replace with your singularideas.com.br image (or leave null for nginx:alpine)
ligflat_site_image         = null                                                        # Replace with your ligflat.com.br image (or leave null for nginx:alpine)
leticiacarvalho_pro_site_image = "ghcr.io/luismr/leticiacarvalho-pro-portfolio:master-ae00107"  # leticiacarvalho.pro portfolio image

carimbo_n8n_timezone      = "America/Sao_Paulo"                                         # Timezone for n8n (TZ and GENERIC_TIMEZONE)

# WAHA Credentials (set via environment variables)
# Set via: export TF_VAR_carimbo_waha_api_key="$WAHA_API_KEY"
# Set via: export TF_VAR_carimbo_waha_dashboard_username="$WAHA_DASHBOARD_USERNAME"
# Set via: export TF_VAR_carimbo_waha_dashboard_password="$WAHA_DASHBOARD_PASSWORD"
# Set via: export TF_VAR_carimbo_waha_swagger_username="$WAHA_SWAGGER_USERNAME"
# Set via: export TF_VAR_carimbo_waha_swagger_password="$WAHA_SWAGGER_PASSWORD"
# carimbo_waha_api_key            = null  # Commented out - use TF_VAR_carimbo_waha_api_key env var instead
# carimbo_waha_dashboard_username = null  # Commented out - use TF_VAR_carimbo_waha_dashboard_username env var instead
# carimbo_waha_dashboard_password  = null  # Commented out - use TF_VAR_carimbo_waha_dashboard_password env var instead
# carimbo_waha_swagger_username    = null  # Commented out - use TF_VAR_carimbo_waha_swagger_username env var instead
# carimbo_waha_swagger_password    = null  # Commented out - use TF_VAR_carimbo_waha_swagger_password env var instead

# PostgreSQL Configuration for carimbo.vip
# Set via: export TF_VAR_carimbo_postgres_password="$POSTGRES_PASSWORD"
# carimbo_postgres_password = null  # Commented out - use TF_VAR_carimbo_postgres_password env var instead
# carimbo_postgres_database_name = "carimbo"  # Optional: defaults to "carimbo"

# GitHub Container Registry (GHCR) Authentication (for private images)
# Leave empty if using public images
# Set via: export TF_VAR_ghcr_username="$GITHUB_USER"
# Set via: export TF_VAR_ghcr_token="$GITHUB_TOKEN"
# ghcr_username = null  # Commented out - use TF_VAR_ghcr_username env var instead
# ghcr_token    = null  # Commented out - use TF_VAR_ghcr_token env var instead
