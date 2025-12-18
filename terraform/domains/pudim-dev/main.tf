# Create namespace for pudim.dev domain
resource "kubernetes_namespace" "pudim_dev" {
  metadata {
    name = "pudim-dev"
    labels = {
      name        = "pudim-dev"
      domain      = "pudim.dev"
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
    namespace = kubernetes_namespace.pudim_dev.metadata[0].name
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

  depends_on = [kubernetes_namespace.pudim_dev]
}

# Deploy Redis cache for pudim.dev calculator
module "pudim_dev_redis" {
  source = "../../modules/redis"

  app_name    = "redis"
  domain      = "redis.pudim.dev"
  namespace   = kubernetes_namespace.pudim_dev.metadata[0].name
  environment = "production"

  # Cache does not require persistence; keep it ephemeral unless you explicitly enable NFS.
  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"

  replicas = 1

  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "50m"
  resource_requests_memory = "128Mi"

  # Ensure the service is reachable inside the cluster without requiring a password.
  protected_mode   = false
  requirepass      = null
  maxmemory        = var.redis_maxmemory
  maxmemory_policy = var.redis_maxmemory_policy

  depends_on = [kubernetes_namespace.pudim_dev]
}

# Deploy DynamoDB Local for pudim.dev
module "pudim_dev_dynamodb_local" {
  source = "../../modules/dynamodb-local"

  app_name    = "dynamodb-local"
  domain      = "dynamodb.pudim.dev"
  namespace   = kubernetes_namespace.pudim_dev.metadata[0].name
  environment = "production"

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"

  replicas = 1

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "256Mi"

  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  depends_on = [kubernetes_namespace.pudim_dev]
}

# ConfigMap for pudim.dev calculator environment variables
resource "kubernetes_config_map_v1" "pudim_dev_calculator_config" {
  metadata {
    name      = "calculator-config"
    namespace = kubernetes_namespace.pudim_dev.metadata[0].name
    labels = {
      app         = "calculator"
      domain      = "pudim.dev"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = {
    # Redis settings
    REDIS_ENABLED                        = var.redis_enabled ? "true" : "false"
    REDIS_URL                            = "redis://${module.pudim_dev_redis.service_name}:6379"
    REDIS_PREFIX                         = var.redis_prefix
    REDIS_TTL                            = tostring(var.redis_ttl)
    REDIS_CIRCUIT_BREAKER_COOLDOWN       = tostring(var.redis_circuit_breaker_cooldown_ms)

    # Leaderboard
    LEADERBOARD_ENABLED                  = var.leaderboard_enabled ? "true" : "false"

    # Frontend debug
    FRONTEND_DEBUG_ENABLED               = var.frontend_debug_enabled ? "true" : "false"

    # DynamoDB settings (only if enabled)
    DYNAMODB_ENABLED                     = var.dynamodb_enabled ? "true" : "false"
    DYNAMODB_ENDPOINT                    = var.dynamodb_enabled ? coalesce(var.dynamodb_endpoint, module.pudim_dev_dynamodb_local.service_url) : ""
    DYNAMODB_CIRCUIT_BREAKER_COOLDOWN    = var.dynamodb_enabled ? tostring(var.dynamodb_circuit_breaker_cooldown_ms) : ""
    AWS_REGION                           = var.dynamodb_enabled ? var.dynamodb_aws_region : ""
    AWS_ACCESS_KEY_ID                    = var.dynamodb_enabled ? var.dynamodb_aws_access_key_id : ""
    AWS_SECRET_ACCESS_KEY                = var.dynamodb_enabled ? var.dynamodb_aws_secret_access_key : ""
  }

  depends_on = [
    kubernetes_namespace.pudim_dev,
    module.pudim_dev_dynamodb_local,
  ]
}

# Deploy pudim.dev application
module "pudim_dev_calculator" {
  source = "../../modules/app-service"

  app_name           = "calculator"
  domain             = "pudim.dev"
  namespace          = kubernetes_namespace.pudim_dev.metadata[0].name
  environment        = "production"
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  # Image provided per domain
  app_image = var.site_image
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  # Application specific settings
  container_port    = 3000
  service_port      = 80 # Exposed internally for the tunnel
  health_check_path = "/api/health"
  health_check_port = 3000

  # Inject application env vars
  config_map_name = kubernetes_config_map_v1.pudim_dev_calculator_config.metadata[0].name

  # Production resource limits
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on = [
    kubernetes_namespace.pudim_dev,
    module.pudim_dev_redis,
    module.pudim_dev_dynamodb_local,
    kubernetes_config_map_v1.pudim_dev_calculator_config,
  ]
}

