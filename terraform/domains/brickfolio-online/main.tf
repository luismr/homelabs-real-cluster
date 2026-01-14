# Create namespace for brickfolio.online domain
resource "kubernetes_namespace" "brickfolio_online" {
  metadata {
    name = "brickfolio-online"
    labels = {
      name        = "brickfolio-online"
      domain      = "brickfolio.online"
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
    namespace = kubernetes_namespace.brickfolio_online.metadata[0].name
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

  depends_on = [kubernetes_namespace.brickfolio_online]
}

# Deploy brickfolio.online site
# Using app-service module because brickfolio-site is a Next.js app running on port 3000
module "brickfolio_online_site" {
  source = "../../modules/app-service"

  app_name           = "static-site"  # Keep service name as "static-site" for tunnel compatibility
  domain             = "brickfolio.online"
  namespace          = kubernetes_namespace.brickfolio_online.metadata[0].name
  environment        = "production"
  replicas           = 1
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  # Image provided per domain
  app_image = coalesce(var.site_image, "nginx:alpine")
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  # Port configuration - Next.js runs on port 3000
  container_port = 3000
  service_port   = 80  # Service exposes on port 80 internally for tunnel

  # Health check configuration
  health_check_path            = "/"
  health_check_port            = 3000  # Match container_port
  health_check_initial_delay   = 30    # Give Next.js time to start
  health_check_period         = 10

  # Production resource limits
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on_resources = [kubernetes_namespace.brickfolio_online]
}

# Deploy brickfolio.online forms service
module "brickfolio_online_forms" {
  count = var.forms_image != null ? 1 : 0

  source = "../../modules/forms"

  app_name           = "forms"
  domain             = "forms.brickfolio.online"
  namespace          = kubernetes_namespace.brickfolio_online.metadata[0].name
  environment        = "production"
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  forms_image            = var.forms_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  # Forms-specific environment variables
  turnstile_secret_key = "0x4AAAAAACCvUECCzvvVh9Yg3Ric5u0dvSs"
  turnstile_enabled    = "true"
  cors_origin          = "https://brickfolio.online"
  n8n_base_url         = var.forms_n8n_base_url
  allowed_controllers  = var.forms_allowed_controllers
  allowed_origins      = var.forms_allowed_origins
  origin_override      = var.forms_origin_override

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

  depends_on_resources = [kubernetes_namespace.brickfolio_online]
}
