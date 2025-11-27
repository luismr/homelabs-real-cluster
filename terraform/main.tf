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

  site_image    = var.carimbo_site_image
  forms_image   = var.carimbo_forms_image
  waha_image    = var.carimbo_waha_image
  waha_api_key  = var.carimbo_waha_api_key
  waha_dashboard_username = var.carimbo_waha_dashboard_username
  waha_dashboard_password = var.carimbo_waha_dashboard_password
  waha_swagger_username   = var.carimbo_waha_swagger_username
  waha_swagger_password   = var.carimbo_waha_swagger_password
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
}

# Deploy ligflat.com.br domain
module "ligflat_com_br" {
  source = "./domains/ligflat-com-br"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image    = var.ligflat_site_image
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
}

# Deploy singularideas.com.br domain
module "singularideas_com_br" {
  source = "./domains/singularideas-com-br"

  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class

  site_image    = var.singularideas_site_image
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
  ]

  depends_on = [kubernetes_namespace.redirects]
}
