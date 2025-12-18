# Deploy monitoring stack (Prometheus, Grafana, Loki with NFS storage)
module "monitoring" {
  source = "./modules/monitoring"

  enable_nfs_storage  = var.enable_nfs_storage
  storage_class       = var.storage_class
  loki_storage_size   = "50Gi"
  loki_retention_days = 30
}

# Create a dedicated namespace for the Cloudflare Tunnel
resource "kubernetes_namespace" "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_token != "" ? 1 : 0

  metadata {
    name = "cloudflare-tunnel"
    labels = {
      name       = "cloudflare-tunnel"
      managed-by = "terraform"
    }
  }
}

# Deploy the shared Cloudflare Tunnel
module "cloudflare_tunnel" {
  count = var.cloudflare_tunnel_token != "" ? 1 : 0

  source = "./modules/cloudflare-tunnel"

  tunnel_token = var.cloudflare_tunnel_token
  namespace    = kubernetes_namespace.cloudflare_tunnel[0].metadata[0].name

  depends_on = [kubernetes_namespace.cloudflare_tunnel]
}

# Orchestrate all domain deployments
# Each domain has its own module in domains/ folder

# Deploy pudim.dev domain
module "pudim_dev" {
  source = "./domains/pudim-dev"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image    = var.pudim_site_image
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token

  redis_enabled                     = var.pudim_redis_enabled
  redis_prefix                      = var.pudim_redis_prefix
  redis_ttl                         = var.pudim_redis_ttl
  redis_circuit_breaker_cooldown_ms = var.pudim_redis_circuit_breaker_cooldown_ms
  redis_maxmemory                   = var.pudim_redis_maxmemory
  redis_maxmemory_policy            = var.pudim_redis_maxmemory_policy

  dynamodb_enabled                     = var.pudim_dynamodb_enabled
  dynamodb_endpoint                    = var.pudim_dynamodb_endpoint
  dynamodb_circuit_breaker_cooldown_ms = var.pudim_dynamodb_circuit_breaker_cooldown_ms
  dynamodb_aws_region                  = var.pudim_dynamodb_aws_region
  dynamodb_aws_access_key_id           = var.pudim_dynamodb_aws_access_key_id
  dynamodb_aws_secret_access_key       = var.pudim_dynamodb_aws_secret_access_key
}

# Deploy luismachadoreis.dev domain
module "luismachadoreis_dev" {
  source = "./domains/luismachadoreis-dev"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image    = var.luismachadoreis_site_image
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
}

# Deploy carimbo.vip domain
module "carimbo_vip" {
  source = "./domains/carimbo-vip"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image                = var.carimbo_site_image
  forms_image               = var.carimbo_forms_image
  forms_n8n_base_url        = var.carimbo_forms_n8n_base_url
  forms_allowed_controllers = var.carimbo_forms_allowed_controllers
  forms_allowed_origins     = var.carimbo_forms_allowed_origins
  forms_origin_override     = var.carimbo_forms_origin_override
  waha_image                = var.carimbo_waha_image
  waha_api_key              = var.carimbo_waha_api_key
  waha_dashboard_username   = var.carimbo_waha_dashboard_username
  waha_dashboard_password   = var.carimbo_waha_dashboard_password
  waha_swagger_username     = var.carimbo_waha_swagger_username
  waha_swagger_password     = var.carimbo_waha_swagger_password
  waha_restart_all_sessions = var.carimbo_waha_restart_all_sessions
  waha_start_session        = var.carimbo_waha_start_session
  waha_hook_url             = var.carimbo_waha_hook_url
  waha_hook_events          = var.carimbo_waha_hook_events
  n8n_image                 = var.carimbo_n8n_image
  n8n_timezone              = var.carimbo_n8n_timezone
  redis_image               = var.carimbo_redis_image
  postgres_image            = var.carimbo_postgres_image
  postgres_password         = var.carimbo_postgres_password
  postgres_database_name    = var.carimbo_postgres_database_name
  postgres_node_port        = var.carimbo_postgres_node_port
  ghcr_username             = var.ghcr_username
  ghcr_token                = var.ghcr_token
}

# Deploy singularideas.com.br domain
module "singularideas_com_br" {
  source = "./domains/singularideas-com-br"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image                = var.singularideas_site_image
  forms_image               = var.singularideas_forms_image
  forms_n8n_base_url        = var.singularideas_forms_n8n_base_url
  forms_allowed_controllers = var.singularideas_forms_allowed_controllers
  forms_allowed_origins     = var.singularideas_forms_allowed_origins
  forms_origin_override     = var.singularideas_forms_origin_override
  waha_image                = var.singularideas_waha_image
  waha_api_key              = var.singularideas_waha_api_key
  waha_dashboard_username   = var.singularideas_waha_dashboard_username
  waha_dashboard_password   = var.singularideas_waha_dashboard_password
  waha_swagger_username     = var.singularideas_waha_swagger_username
  waha_swagger_password     = var.singularideas_waha_swagger_password
  waha_restart_all_sessions = var.singularideas_waha_restart_all_sessions
  waha_start_session        = var.singularideas_waha_start_session
  waha_hook_url             = var.singularideas_waha_hook_url
  waha_hook_events          = var.singularideas_waha_hook_events
  ghcr_username             = var.ghcr_username
  ghcr_token                = var.ghcr_token
}

# Deploy leticiacarvalho.pro domain
module "leticiacarvalho_pro" {
  source = "./domains/leticiacarvalho-pro"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image    = var.leticiacarvalho_pro_site_image
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
}

# Redirects namespace and redirector deployment
resource "kubernetes_namespace" "redirects" {
  metadata {
    name = "redirects"
    labels = {
      name       = "redirects"
      managed-by = "terraform"
    }
  }
}

module "redirects" {
  source    = "./modules/nginx-redirector"
  namespace = kubernetes_namespace.redirects.metadata[0].name

  rules = [
    {
      sources = ["luismachadoreis.dev.br", "*.luismachadoreis.dev.br"]
      target  = "luismachadoreis.dev"
      code    = 301
    },
    {
      sources = ["pudim.dev.br", "*.pudim.dev.br"]
      target  = "pudim.dev"
      code    = 301
    },
    {
      sources = [
        "carimbovip.com.br", "*.carimbovip.com.br",
        "carimbovip.com", "*.carimbovip.com",
      ]
      target = "carimbo.vip"
      code   = 301
    },
    {
      sources = ["singularideias.com.br", "*.singularideias.com.br"]
      target  = "singularideas.com.br"
      code    = 301
    },
    {
      sources = ["ligflat.com.br", "*.ligflat.com.br"]
      target  = "singularideas.com.br"
      code    = 301
    },
  ]

  depends_on = [kubernetes_namespace.redirects]
}
