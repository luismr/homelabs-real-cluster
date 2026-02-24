# Create namespace for luismachadoreis.dev domain
resource "kubernetes_namespace" "luismachadoreis_dev" {
  metadata {
    name = "luismachadoreis-dev"
    labels = {
      name        = "luismachadoreis-dev"
      domain      = "luismachadoreis.dev"
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
    namespace = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
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

  depends_on = [kubernetes_namespace.luismachadoreis_dev]
}

# Deploy luismachadoreis.dev static site
module "luismachadoreis_dev_site" {
  source = "../../modules/nginx-static-site"

  site_name          = "luismachadoreis-dev"
  domain             = "luismachadoreis.dev"
  namespace          = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
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

  depends_on = [kubernetes_namespace.luismachadoreis_dev]
}

# Deploy MCP Blueprint Prompts SSE backend service
module "mcp_blueprint_prompts_sse" {
  source = "../../modules/app-service"

  app_name           = "mcp-blueprint-prompts-sse"
  domain             = "luismachadoreis.dev"
  namespace          = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
  environment        = "production"
  replicas           = 1
  enable_autoscaling = false
  enable_nfs         = false

  app_image              = var.mcp_blueprint_prompts_sse_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  container_port    = 9000
  service_port      = 9000
  health_check_path = "/mcp"
  health_check_port = 9000

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  # No NodePort needed (internal service)
  enable_cloudflare_tunnel = false

  depends_on_resources = [kubernetes_namespace.luismachadoreis_dev]
}

# Deploy MCP Blueprint Prompts frontend with nginx proxy
module "mcp_blueprint_prompts_frontend" {
  source = "../../modules/nginx-static-site"

  site_name          = "mcp-blueprint-prompts"
  domain             = "prompts.luismachadoreis.dev"
  namespace          = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
  environment        = "production"
  replicas           = 1
  enable_autoscaling = false
  enable_nfs         = false

  # Use the site image for static content
  nginx_image            = var.mcp_blueprint_prompts_site_image
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  # Configure proxy routes - /mcp requests go to the SSE backend
  proxy_routes = {
    "/mcp" = "http://mcp-blueprint-prompts-sse.${kubernetes_namespace.luismachadoreis_dev.metadata[0].name}.svc.cluster.local:9000"
  }

  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  depends_on = [
    kubernetes_namespace.luismachadoreis_dev,
    module.mcp_blueprint_prompts_sse
  ]
}
