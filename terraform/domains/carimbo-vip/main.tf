# Create namespace for carimbo.vip domain
resource "kubernetes_namespace" "carimbo_vip" {
  metadata {
    name = "carimbo-vip"
    labels = {
      name        = "carimbo-vip"
      domain      = "carimbo.vip"
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
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
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

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deploy carimbo.vip static site
module "carimbo_vip_site" {
  source = "../../modules/nginx-static-site"

  site_name          = "carimbo-vip"
  domain             = "carimbo.vip"
  namespace          = kubernetes_namespace.carimbo_vip.metadata[0].name
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

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# ConfigMap for forms service environment variables
resource "kubernetes_config_map_v1" "forms_config" {
  count = var.forms_image != null ? 1 : 0

  metadata {
    name      = "forms-config"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "forms"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = {
    TURNSTILE_SECRET_KEY = "0x4AAAAAACCvUECCzvvVh9Yg3Ric5u0dvSs"
    TURNSTILE_ENABLED    = "true"
    CORS_ORIGIN          = "https://carimbo.vip"
  }

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deploy carimbo.vip forms service
module "carimbo_vip_forms" {
  count = var.forms_image != null ? 1 : 0

  source = "../../modules/app-service"

  app_name           = "forms"
  domain             = "forms.carimbo.vip"
  namespace          = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment        = "production"
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "1Gi"

  # Image provided per domain
  app_image = var.forms_image
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)
  # Use ConfigMap for environment variables
  config_map_name = try(kubernetes_config_map_v1.forms_config[0].metadata[0].name, null)

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

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_config_map_v1.forms_config
  ]
}

# ConfigMap for WAHA service environment variables
resource "kubernetes_config_map_v1" "waha_config" {
  count = var.waha_image != null ? 1 : 0

  metadata {
    name      = "waha-config"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "waha"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = merge(
    {
      # Configure WAHA to use the persistent volume mounted at /data
      WHATSAPP_HOME = "/data"
      # Enable API endpoints
      API_ENABLED = "true"
      # WhatsApp engine configuration
      WHATSAPP_DEFAULT_ENGINE = "GOWS"
    },
    var.waha_api_key != null ? { WAHA_API_KEY = var.waha_api_key } : {},
    var.waha_dashboard_username != null ? { WAHA_DASHBOARD_USERNAME = var.waha_dashboard_username } : {},
    var.waha_dashboard_password != null ? { WAHA_DASHBOARD_PASSWORD = var.waha_dashboard_password } : {},
    var.waha_swagger_username != null ? { WHATSAPP_SWAGGER_USERNAME = var.waha_swagger_username } : {},
    var.waha_swagger_password != null ? { WHATSAPP_SWAGGER_PASSWORD = var.waha_swagger_password } : {}
  )

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deploy carimbo.vip WAHA (WhatsApp HTTP API) service
module "carimbo_vip_waha" {
  count = var.waha_image != null ? 1 : 0

  source = "../../modules/app-service"

  app_name           = "waha"
  domain             = "waha.carimbo.vip"
  namespace          = kubernetes_namespace.carimbo_vip.metadata[0].name
  environment        = "production"
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  enable_nfs         = var.enable_nfs_storage
  storage_class      = var.storage_class
  storage_size       = "5Gi" # WAHA needs more storage for session data

  # Image provided per domain
  app_image = var.waha_image
  # Use imagePullSecret when created
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)
  # Use ConfigMap for environment variables
  config_map_name = try(kubernetes_config_map_v1.waha_config[0].metadata[0].name, null)

  # Application specific settings
  container_port             = 3000 # WAHA default port
  service_port               = 80   # Exposed internally for the tunnel
  health_check_path          = "/ping" # Use ping endpoint which doesn't require auth
  health_check_port          = 3000
  health_check_initial_delay = 30 # WAHA may take longer to start
  health_check_period        = 15

  # Production resource limits (WAHA may need more resources)
  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "200m"
  resource_requests_memory = "256Mi"
  
  # Disable Cloudflare Tunnel (expose via NodePort instead)
  enable_cloudflare_tunnel = false

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_config_map_v1.waha_config,
    kubernetes_secret_v1.ghcr_pull
  ]
}

# NodePort service for WAHA (exposed like Grafana)
resource "kubernetes_service" "waha_nodeport" {
  count = var.waha_image != null ? 1 : 0

  metadata {
    name      = "waha-nodeport"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "waha"
      domain      = "waha.carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      app = "waha"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      node_port   = 30100 # Similar to Grafana's 30080, using 30100 for WAHA
      protocol    = "TCP"
    }
  }

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    module.carimbo_vip_waha
  ]
}

# ConfigMap for n8n service environment variables
resource "kubernetes_config_map_v1" "n8n_config" {
  count = var.n8n_image != null ? 1 : 0

  metadata {
    name      = "n8n-config"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "n8n"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = {
    GENERIC_TIMEZONE                        = var.n8n_timezone
    TZ                                     = var.n8n_timezone
    N8N_PORT                               = "5678"
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS  = "true"
    N8N_RUNNERS_ENABLED                    = "true"
    QUEUE_HEALTH_CHECK_ACTIVE              = "true"
  }

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# PersistentVolumeClaim for n8n data
resource "kubernetes_persistent_volume_claim" "n8n_data" {
  count = (var.n8n_image != null && var.enable_nfs_storage) ? 1 : 0

  metadata {
    name      = "n8n-data"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "n8n"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace.carimbo_vip]
}

# Deployment for n8n
resource "kubernetes_deployment" "n8n" {
  count = var.n8n_image != null ? 1 : 0

  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "n8n"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "n8n"
      }
    }

    template {
      metadata {
        labels = {
          app         = "n8n"
          domain      = "carimbo.vip"
          environment = "production"
        }
      }

      spec {
        # Optional imagePullSecrets for private registries
        dynamic "image_pull_secrets" {
          for_each = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null) != null ? [1] : []
          content {
            name = kubernetes_secret_v1.ghcr_pull[0].metadata[0].name
          }
        }

        container {
          name  = "n8n"
          image = var.n8n_image

          port {
            container_port = 5678
            protocol       = "TCP"
          }

          # Load environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.n8n_config[0].metadata[0].name
            }
          }

          # Mount persistent volume at /home/node/.n8n
          dynamic "volume_mount" {
            for_each = var.enable_nfs_storage ? [1] : []
            content {
              name       = "n8n-data"
              mount_path = "/home/node/.n8n"
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 5678
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/healthz/readiness"
              port = 5678
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        # Data volume only when NFS is enabled
        dynamic "volume" {
          for_each = var.enable_nfs_storage ? [1] : []
          content {
            name = "n8n-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.n8n_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_config_map_v1.n8n_config
  ]
}

# Service for n8n (ClusterIP)
resource "kubernetes_service" "n8n" {
  count = var.n8n_image != null ? 1 : 0

  metadata {
    name      = "n8n"
    namespace = kubernetes_namespace.carimbo_vip.metadata[0].name
    labels = {
      app         = "n8n"
      domain      = "carimbo.vip"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    selector = {
      app = "n8n"
    }

    port {
      name        = "http"
      port        = 5678
      target_port = 5678
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [
    kubernetes_namespace.carimbo_vip,
    kubernetes_deployment.n8n
  ]
}


