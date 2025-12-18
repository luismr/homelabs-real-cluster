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
pudim_site_image                        = "ghcr.io/luismr/pudim-dev-calculator:sha-0a0bc6f"                                            # Replace with your pudim.dev image
luismachadoreis_site_image              = "ghcr.io/luismr/luismachadoreis-dev-portfolio:sha-0022a05"                                   # Replace with your luismachadoreis.dev image
carimbo_site_image                      = "ghcr.io/luismr/carimbo-vip-site:sha-3a19b2c"                                                # Replace with your carimbo.vip image
carimbo_forms_image                     = "ghcr.io/luismr/carimbo-vip-forms:main-8c2e0e7"                                              # Replace with your carimbo.vip forms image
carimbo_forms_n8n_base_url              = "http://n8n.carimbo-vip.svc.cluster.local:5678/webhook/9c49552a-ccdc-4805-b4ee-c69074c371bb" # Base URL for N8N webhook endpoints (e.g., https://n8n.example.com/webhook)
carimbo_forms_allowed_controllers       = "leads,contacts"                                                                             # Comma-separated list of allowed controllers for forms service
carimbo_forms_allowed_origins           = "carimbo.vip"                                                                                # Comma-separated list of allowed origins for forms service
carimbo_forms_origin_override           = "carimbo.vip"                                                                                # Origin override for forms service
carimbo_waha_image                      = "devlikeapro/waha:arm"                                                                       # WAHA (WhatsApp HTTP API) image - ARM64 version
singularideas_waha_image                = "devlikeapro/waha:arm"                                                                       # WAHA (WhatsApp HTTP API) image for singularideas.com.br - ARM64 version (same as carimbo-vip)
carimbo_n8n_image                       = "docker.n8n.io/n8nio/n8n"                                                                    # n8n workflow automation image
singularideas_site_image                = "ghcr.io/luismr/singularideas-com-site:sha-d6254da"                                          # Replace with your singularideas.com.br image (or leave null for nginx:alpine)
singularideas_forms_image               = "ghcr.io/luismr/carimbo-vip-forms:main-8c2e0e7"                                              # Image for singularideas.com.br forms service (using same as carimbo-vip)
singularideas_forms_n8n_base_url        = "http://n8n.carimbo-vip.svc.cluster.local:5678/webhook/9c49552a-ccdc-4805-b4ee-c69074c371bb" # Base URL for N8N webhook endpoints for forms service (using same as carimbo-vip)
singularideas_forms_allowed_controllers = "contacts"                                                                                   # Comma-separated list of allowed controllers for forms service
singularideas_forms_allowed_origins     = "singularideas.com.br"                                                                       # Comma-separated list of allowed origins for forms service
singularideas_forms_origin_override     = "singularideas.com.br"                                                                       # Origin override for forms service
leticiacarvalho_pro_site_image          = "ghcr.io/luismr/leticiacarvalho-pro-portfolio:master-ae00107"                                # leticiacarvalho.pro portfolio image

# pudim.dev Redis cache settings (for pudim-dev-calculator)
pudim_redis_enabled                     = true
pudim_redis_prefix                      = "pudim:"
pudim_redis_ttl                         = 3600
pudim_redis_circuit_breaker_cooldown_ms = 60000
pudim_redis_maxmemory                   = "128mb"
pudim_redis_maxmemory_policy            = "allkeys-lru"

# pudim.dev DynamoDB settings (for pudim-dev-calculator)
pudim_dynamodb_enabled                     = true
pudim_dynamodb_endpoint                    = null  # null = use DynamoDB Local service URL automatically
pudim_dynamodb_circuit_breaker_cooldown_ms = 300000  # 5 minutes
pudim_dynamodb_aws_region                  = "us-east-1"
pudim_dynamodb_aws_access_key_id           = "local"
pudim_dynamodb_aws_secret_access_key       = "local"

carimbo_n8n_timezone = "America/Sao_Paulo" # Timezone for n8n (TZ and GENERIC_TIMEZONE)

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

# WAHA Credentials for singularideas.com.br (using same values as carimbo-vip)
# Set via: export TF_VAR_singularideas_waha_api_key="$WAHA_API_KEY"
# Set via: export TF_VAR_singularideas_waha_dashboard_username="$WAHA_DASHBOARD_USERNAME"
# Set via: export TF_VAR_singularideas_waha_dashboard_password="$WAHA_DASHBOARD_PASSWORD"
# Set via: export TF_VAR_singularideas_waha_swagger_username="$WAHA_SWAGGER_USERNAME"
# Set via: export TF_VAR_singularideas_waha_swagger_password="$WAHA_SWAGGER_PASSWORD"
# singularideas_waha_api_key            = null  # Commented out - use TF_VAR_singularideas_waha_api_key env var instead
# singularideas_waha_dashboard_username = null  # Commented out - use TF_VAR_singularideas_waha_dashboard_username env var instead
# singularideas_waha_dashboard_password  = null  # Commented out - use TF_VAR_singularideas_waha_dashboard_password env var instead
# singularideas_waha_swagger_username    = null  # Commented out - use TF_VAR_singularideas_waha_swagger_username env var instead
# singularideas_waha_swagger_password    = null  # Commented out - use TF_VAR_singularideas_waha_swagger_password env var instead

# WAHA Configuration
carimbo_waha_restart_all_sessions       = true                                                                                              # Enable restart all WhatsApp sessions on startup for carimbo.vip WAHA
carimbo_waha_start_session              = "default"                                                                                         # WhatsApp session to start automatically for carimbo.vip WAHA
carimbo_waha_hook_url                   = "http://n8n.carimbo-vip.svc.cluster.local:5678/webhook/64bee5f6-129c-426d-986d-5ec70549dd76/waha" # Webhook URL for carimbo.vip WAHA
singularideas_waha_restart_all_sessions = true                                                                                              # Enable restart all WhatsApp sessions on startup for singularideas.com.br WAHA
singularideas_waha_start_session        = "default"                                                                                         # WhatsApp session to start automatically for singularideas.com.br WAHA
singularideas_waha_hook_url             = "http://n8n.carimbo-vip.svc.cluster.local:5678/webhook/d7e91a31-bca3-4f32-a25c-19ab61ff8016/waha" # Webhook URL for singularideas.com.br WAHA

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
