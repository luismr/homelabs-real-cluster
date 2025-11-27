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

# Deploy ligflat.com.br static site
module "ligflat_com_br_site" {
  source = "../../modules/nginx-static-site"

  site_name    = "ligflat-com-br"
  domain       = "ligflat.com.br"
  namespace    = kubernetes_namespace.ligflat_com_br.metadata[0].name
  environment  = "production"
  
  enable_nfs   = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"
  
  replicas = 2

  depends_on = [kubernetes_namespace.ligflat_com_br]
}

