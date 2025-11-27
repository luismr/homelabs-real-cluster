# Create namespace for ligflat.com.br domain
resource "kubernetes_namespace" "ligflat_com_br" {
  metadata {
    name = "ligflat-com-br"
    labels = {
      name        = "ligflat-com-br"
      domain      = "ligflat.com.br"
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
    namespace = kubernetes_namespace.ligflat_com_br.metadata[0].name
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

  depends_on = [kubernetes_namespace.ligflat_com_br]
}

# Deploy ligflat.com.br static site
module "ligflat_com_br_site" {
  source = "../../modules/nginx-static-site"

  site_name   = "ligflat-com-br"
  domain      = "ligflat.com.br"
  namespace   = kubernetes_namespace.ligflat_com_br.metadata[0].name
  environment = "production"

  enable_nfs    = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"

  replicas = 2

  # Image provided per domain (falls back to nginx:alpine)
  nginx_image = coalesce(var.site_image, "nginx:alpine")
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  depends_on = [kubernetes_namespace.ligflat_com_br]
}

