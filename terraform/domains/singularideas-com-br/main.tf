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

# Deploy singularideas.com.br static site
module "singularideas_com_br_site" {
  source = "../../modules/nginx-static-site"

  site_name    = "singularideas-com-br"
  domain       = "singularideas.com.br"
  namespace    = kubernetes_namespace.singularideas_com_br.metadata[0].name
  environment  = "production"
  
  enable_nfs   = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size  = "1Gi"
  
  replicas = 2

  depends_on = [kubernetes_namespace.singularideas_com_br]
}

