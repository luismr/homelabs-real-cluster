# Create namespace for singularideas.com.br domain
resource "kubernetes_namespace" "singularideas_com_br" {
  metadata {
    name = "singularideas-com-br"
    labels = {
      name        = "singularideas-com-br"
      domain      = "singularideas.com.br"
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
    namespace = kubernetes_namespace.singularideas_com_br.metadata[0].name
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

  depends_on = [kubernetes_namespace.singularideas_com_br]
}

# Deploy singularideas.com.br static site
module "singularideas_com_br_site" {
  source = "../../modules/nginx-static-site"

  site_name   = "singularideas-com-br"
  domain      = "singularideas.com.br"
  namespace   = kubernetes_namespace.singularideas_com_br.metadata[0].name
  environment = "production"

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"

  replicas = 2

  # Image provided per domain (falls back to nginx:alpine)
  nginx_image = coalesce(var.site_image, "nginx:alpine")
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  depends_on = [kubernetes_namespace.singularideas_com_br]
}

# Deploy singularideas.com.br WAHA (WhatsApp HTTP API) service
module "singularideas_com_br_waha" {
  count = var.waha_image != null ? 1 : 0

  source = "../../modules/waha"

  app_name               = "waha"
  domain                 = "waha.singularideas.com.br"
  namespace              = kubernetes_namespace.singularideas_com_br.metadata[0].name
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

  node_port = 30101 # Using 30101 for singularideas (30100 is used by carimbo-vip)

  enable_autoscaling = false # WAHA should run as single instance
  min_replicas       = 1
  max_replicas       = 1

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"

  depends_on = [
    kubernetes_namespace.singularideas_com_br,
    kubernetes_secret_v1.ghcr_pull
  ]
}

