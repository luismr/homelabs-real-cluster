# ConfigMap for forms service environment variables
resource "kubernetes_config_map_v1" "forms_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = merge(
    var.turnstile_secret_key != null ? { TURNSTILE_SECRET_KEY = var.turnstile_secret_key } : {},
    { TURNSTILE_ENABLED = var.turnstile_enabled },
    var.cors_origin != null ? { CORS_ORIGIN = var.cors_origin } : {},
    { ALLOWED_CONTROLLERS = var.allowed_controllers },
    { ALLOWED_ORIGINS = var.allowed_origins },
    { ORIGIN_OVERRIDE = var.origin_override },
    var.n8n_base_url != null ? { N8N_BASE_URL = var.n8n_base_url } : {}
  )
}

# Deploy forms service using app-service module
module "forms_app" {
  source = "../app-service"

  app_name           = var.app_name
  domain             = var.domain
  namespace          = var.namespace
  environment        = var.environment
  enable_autoscaling = var.enable_autoscaling
  min_replicas       = var.min_replicas
  max_replicas       = var.max_replicas
  enable_nfs         = var.enable_nfs
  storage_class      = var.storage_class
  storage_size       = var.storage_size

  app_image              = var.forms_image
  image_pull_secret_name = var.image_pull_secret_name
  config_map_name        = kubernetes_config_map_v1.forms_config.metadata[0].name

  container_port    = var.container_port
  service_port      = var.service_port
  health_check_path = var.health_check_path
  health_check_port = var.health_check_port

  resource_limits_cpu      = var.resource_limits_cpu
  resource_limits_memory   = var.resource_limits_memory
  resource_requests_cpu    = var.resource_requests_cpu
  resource_requests_memory = var.resource_requests_memory

  depends_on_resources = var.depends_on_resources
}

