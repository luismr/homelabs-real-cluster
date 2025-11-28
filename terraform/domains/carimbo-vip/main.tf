# Create namespace for carimbo.vip domain
resource "kubernetes_namespace" "carimbo_vip" {
  metadata {
    name = "carimbo-vip"
    labels = {
      name        = "carimbo-vip"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }
}

# Optional: GHCR image pull secret (created only if creds provided)
resource "kubernetes_secret_v1" "ghcr_pull" {
  count = (var.ghcr_username != null && var.ghcr_token != null) ? 1 : 0

  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_token
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_token}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deploy carimbo.vip static site
module "carimbo_vip_site" {
  source = "../../modules/nginx-static-site"

  site_name          = "carimbo-vip"
  domain             = "carimbo.vip"
  namespace          = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment        = "production"
  replicas           = 1
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  # Image provided per domain (falls back to nginx:alpine)
  nginx_image = coalesce(var.site_image, "nginx:alpine")
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  # Production resource limits
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# ConfigMap for forms service environment variables
resource "kubernetes_config_map_v1" "forms_config" {
  count = var.forms_image != null ? 1 : 0

  metadata {
    name      = "forms-config"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "forms"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = {
    TURNSTILE_SECRET_KEY = "0x4AAAAAACCvUECCzvvVh9Yg3Ric5u0dvSs"
    TURNSTILE_ENABLED    = "true"
    CORS_ORIGIN          = "https://carimbo.vip"
  }

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deploy carimbo.vip forms service
module "carimbo_vip_forms" {
  count = var.forms_image != null ? 1 : 0

  source = "../../modules/app-service"

  app_name           = "forms"
  domain             = "forms.carimbo.vip"
  namespace          = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment        = "production"
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  # Image provided per domain
  app_image = var.forms_image
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)
  # Use ConfigMap for environment variables
  config_map_name = try(kubernetes_config_map_v1.forms_config[0].metadata[0].name, null)

  # Application specific settings
  container_port    = 3000
  service_port      = 80 # Exposed internally for the tunnel
  health_check_path = "/health"
  health_check_port = 3000

  # Production resource limits
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_config_map_v1.forms_config
  ]
}

# Deploy carimbo.vip WAHA (WhatsApp HTTP API) service
module "carimbo_vip_waha" {
  count = var.waha_image != null ? 1 : 0

  source = "../../modules/waha"

  app_name               = "waha"
  domain                 = "waha.carimbo.vip"
  namespace              = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment            = "production"
  waha_image             = var.waha_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "5Gi" # WAHA needs more storage for session data

  waha_api_key            = var.waha_api_key
  waha_dashboard_username = var.waha_dashboard_username
  waha_dashboard_password = var.waha_dashboard_password
  waha_swagger_username   = var.waha_swagger_username
  waha_swagger_password   = var.waha_swagger_password

  node_port = 30100 # Similar to Grafana's 30080, using 30100 for WAHA

  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# Deploy carimbo.vip n8n service
module "carimbo_vip_n8n" {
  count = var.n8n_image != null ? 1 : 0

  source = "../../modules/n8n"

  app_name               = "n8n"
  domain                 = "n8n.carimbo.vip"
  namespace              = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment            = "production"
  n8n_image              = var.n8n_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "5Gi"

  n8n_timezone = var.n8n_timezone

  replicas = 1

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"

  enable_cloudflare_tunnel = false

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# Deploy carimbo.vip Redis service
module "carimbo_vip_redis" {
  source = "../../modules/redis"

  app_name               = "redis"
  domain                 = "redis.carimbo.vip"
  namespace              = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment            = "production"
  redis_image            = coalesce(var.redis_image, "redis:7-alpine")
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "2Gi" # Redis data storage for id generator state

  replicas = 1

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "256Mi"

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# Deploy carimbo.vip PostgreSQL service with pgvector
module "carimbo_vip_postgres" {
  source = "../../modules/postgres"

  app_name               = "postgres"
  domain                 = "postgres.carimbo.vip"
  namespace              = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment            = "production"
  postgres_image         = coalesce(var.postgres_image, "pgvector/pgvector:pg17")
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "20Gi" # PostgreSQL data storage

  replicas = 1

  postgres_user     = "postgres"
  postgres_password = var.postgres_password
  database_name     = var.postgres_database_name
  enable_pgvector   = true
  node_port         = var.postgres_node_port # NodePort for external access (like Grafana)

  resource_limits_cpu      = "1000m"
  resource_limits_memory   = "1Gi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "512Mi"

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_secret_v1.ghcr_pull
  ]
}



