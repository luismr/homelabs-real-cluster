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
  
  site_name         = "luismachadoreis-dev"
  domain            = "luismachadoreis.dev"
  namespace         = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
  environment       = "production"
  replicas          = 3
  enable_nfs        = var.enable_nfs_storage
  storage_class     = var.storage_class
  storage_size      = "1Gi"
  
  # Image provided per domain (falls back to nginx:alpine)
  nginx_image       = coalesce(var.site_image, "nginx:alpine")
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)
  
  # Production resource limits
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"
  
  depends_on = [kubernetes_namespace.luismachadoreis_dev]
}

