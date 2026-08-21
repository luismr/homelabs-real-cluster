# Create namespace for this brickfolio environment (QA or PROD)
resource "kubernetes_namespace" "brickfolio_env" {
  metadata {
    name = var.namespace_name
    labels = {
      name        = var.namespace_name
      domain      = "brickfolio.online"
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Optional: GHCR image pull secret (created only if creds provided)
resource "kubernetes_secret_v1" "ghcr_pull" {
  count = (var.ghcr_username != null && var.ghcr_token != null) ? 1 : 0

  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace.brickfolio_env.metadata[0].name
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

  depends_on = [kubernetes_namespace.brickfolio_env]
}

# Redis (no password, no ACL)
module "redis" {
  source = "../../modules/redis"

  app_name               = "redis"
  domain                 = "redis.${var.namespace_name}.local"
  namespace              = kubernetes_namespace.brickfolio_env.metadata[0].name
  environment            = var.environment
  redis_image            = "redis:7-alpine"
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs            = var.enable_nfs_storage
  storage_class         = var.storage_class
  storage_size          = "1Gi"
  replicas              = 1
  protected_mode        = false
  requirepass           = null
  acl_users             = []
  enable_servicemonitor = false
  depends_on_resources  = [kubernetes_namespace.brickfolio_env]
  loglevel              = "verbose" # log client connections; set to "notice" to reduce noise

  depends_on = [
    kubernetes_namespace.brickfolio_env,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# Postgres 17 (standard image, brickfolio_db, user brickfolio)
module "postgres" {
  source = "../../modules/postgres"

  app_name               = "postgres"
  domain                 = "postgres.${var.namespace_name}.local"
  namespace              = kubernetes_namespace.brickfolio_env.metadata[0].name
  environment            = var.environment
  postgres_image         = "postgres:17-alpine"
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  enable_nfs            = var.enable_nfs_storage
  storage_class         = var.storage_class
  storage_size          = "5Gi"
  replicas              = 1
  postgres_user         = "brickfolio"
  postgres_password     = var.postgres_password
  database_name         = "brickfolio_db"
  enable_pgvector       = false
  node_port             = var.postgres_node_port
  enable_servicemonitor = false
  depends_on_resources  = [kubernetes_namespace.brickfolio_env]

  depends_on = [
    kubernetes_namespace.brickfolio_env,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# API ConfigMap (non-secret env vars for Spring Boot)
resource "kubernetes_config_map_v1" "api_config" {
  metadata {
    name      = "api-config"
    namespace = kubernetes_namespace.brickfolio_env.metadata[0].name
    labels = {
      app         = "api"
      domain      = var.api_public_host
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    # Database (spring.datasource.*)
    DATABASE_URL      = "jdbc:postgresql://postgres:5432/brickfolio_db"
    DATABASE_USERNAME = "brickfolio"

    # Redis (spring.data.redis.*) — hostname must match Redis Service name in this namespace
    REDIS_HOST = module.redis.service_name
    REDIS_PORT = tostring(module.redis.service_port)

    # JWT (jwt.*)
    JWT_ISSUER             = "brickfolio-app"
    JWT_AUDIENCE           = "brickfolio-api"
    JWT_EXPIRATION_SECONDS = "3600"

    # CORS (app.cors.allowed-origins[0])
    APP_CORS_ALLOWED_ORIGINS_0 = var.api_cors_allowed_origins

    # Token cleanup (app.tokens.*)
    APP_TOKENS_CLEANUP_CRON              = "0 */10 * * * *"
    APP_TOKENS_EXPIRED_RETENTION_MINUTES = "10"
    APP_TOKENS_CLEANUP_LOCK_KEY          = "brickfolio:token-cleanup:lock"
    APP_TOKENS_CLEANUP_LOCK_TTL_SECONDS  = "900"
  }

  depends_on = [kubernetes_namespace.brickfolio_env]
}

# API Secret (sensitive env vars)
resource "kubernetes_secret_v1" "api_secrets" {
  metadata {
    name      = "api-secrets"
    namespace = kubernetes_namespace.brickfolio_env.metadata[0].name
    labels = {
      app         = "api"
      domain      = var.api_public_host
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  type = "Opaque"

  data = merge(
    {
      DATABASE_PASSWORD = base64encode(var.postgres_password)
    },
    var.api_jwt_secret != null ? { JWT_SECRET = base64encode(var.api_jwt_secret) } : {},
    var.mapbox_access_token != null ? { MAPBOX_ACCESS_TOKEN = base64encode(var.mapbox_access_token) } : {}
  )

  depends_on = [kubernetes_namespace.brickfolio_env]
}

# App ConfigMap (VITE_* env vars for SPA)
resource "kubernetes_config_map_v1" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.brickfolio_env.metadata[0].name
    labels = {
      app         = "app"
      domain      = var.app_public_host
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    VITE_API_URL     = "https://${var.api_public_host}"
    VITE_AUTH_MODE   = "api"
    VITE_API_TIMEOUT = "10000"
  }

  depends_on = [kubernetes_namespace.brickfolio_env]
}

# API deployment (Spring Boot, port 8080)
module "api" {
  source = "../../modules/app-service"

  app_name               = "api"
  domain                 = var.api_public_host
  namespace              = kubernetes_namespace.brickfolio_env.metadata[0].name
  environment            = var.environment
  replicas               = var.api_replicas
  enable_autoscaling     = false
  enable_nfs             = false
  app_image              = var.api_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  container_port = 8080
  service_port   = 80

  health_check_path          = "/actuator/health/readiness"
  health_check_port          = 8080
  health_check_initial_delay = 40
  health_check_period        = 10

  # Startup probe: give Spring Boot time to start before liveness can kill the container (max ~5 min)
  startup_probe_enabled               = true
  startup_probe_initial_delay_seconds = 30
  startup_probe_period_seconds        = 20
  startup_probe_failure_threshold     = 90

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"

  config_map_name      = kubernetes_config_map_v1.api_config.metadata[0].name
  env_from_secret_name = kubernetes_secret_v1.api_secrets.metadata[0].name

  # API readiness depends on Postgres and Redis; allow 30 min for first rollout
  progress_deadline_seconds = 1800

  depends_on_resources = [kubernetes_namespace.brickfolio_env]
}

# App deployment (SPA, port 80; VITE_* baked in pipeline)
module "app" {
  source = "../../modules/app-service"

  app_name               = "app"
  domain                 = var.app_public_host
  namespace              = kubernetes_namespace.brickfolio_env.metadata[0].name
  environment            = var.environment
  replicas               = var.app_replicas
  enable_autoscaling     = false
  enable_nfs             = false
  app_image              = var.app_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  config_map_name = kubernetes_config_map_v1.app_config.metadata[0].name

  container_port = 80
  service_port   = 80

  health_check_path = "/"
  health_check_port = 80

  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on_resources = [
    kubernetes_namespace.brickfolio_env
  ]
}
