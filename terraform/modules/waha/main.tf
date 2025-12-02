# ConfigMap for WAHA service environment variables
resource "kubernetes_config_map_v1" "waha_config" {
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
    {
      # Configure WAHA to use the persistent volume mounted at /data
      WHATSAPP_HOME = "/data"
      # Enable API endpoints
      API_ENABLED = "true"
      # WhatsApp engine configuration
      WHATSAPP_DEFAULT_ENGINE = "GOWS"
      # Restart all sessions on startup
      WHATSAPP_RESTART_ALL_SESSIONS = var.waha_restart_all_sessions ? "True" : "False"
    },
    var.waha_api_key != null ? { WAHA_API_KEY = var.waha_api_key } : {},
    var.waha_dashboard_username != null ? { WAHA_DASHBOARD_USERNAME = var.waha_dashboard_username } : {},
    var.waha_dashboard_password != null ? { WAHA_DASHBOARD_PASSWORD = var.waha_dashboard_password } : {},
    var.waha_swagger_username != null ? { WHATSAPP_SWAGGER_USERNAME = var.waha_swagger_username } : {},
    var.waha_swagger_password != null ? { WHATSAPP_SWAGGER_PASSWORD = var.waha_swagger_password } : {},
    var.waha_start_session != null ? { WHATSAPP_START_SESSION = var.waha_start_session } : {}
  )
}

# PersistentVolumeClaim for WAHA data (optional)
resource "kubernetes_persistent_volume_claim" "waha_data" {
  count = var.enable_nfs ? 1 : 0

  metadata {
    name      = "${var.app_name}-data"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

# Deployment for WAHA service
resource "kubernetes_deployment" "waha" {

  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    replicas = var.enable_autoscaling ? var.min_replicas : 1

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app         = var.app_name
          domain      = var.domain
          environment = var.environment
        }
      }

      spec {
        # Optional imagePullSecrets for private registries
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name != null ? [1] : []
          content {
            name = var.image_pull_secret_name
          }
        }

        container {
          name  = var.app_name
          image = var.waha_image

          port {
            container_port = 3000
            protocol       = "TCP"
          }

          # Load environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.waha_config.metadata[0].name
            }
          }

          # Mount persistent volume at /data
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "waha-data"
              mount_path = "/data"
            }
          }

          # Mount sessions directory for WAHA session persistence
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "waha-data"
              mount_path = "/app/.sessions"
              sub_path   = "sessions"
            }
          }

          resources {
            limits = {
              cpu    = var.resource_limits_cpu
              memory = var.resource_limits_memory
            }
            requests = {
              cpu    = var.resource_requests_cpu
              memory = var.resource_requests_memory
            }
          }

          liveness_probe {
            http_get {
              path = "/ping"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path = "/ping"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        # Data volume only when NFS is enabled
        dynamic "volume" {
          for_each = var.enable_nfs ? [1] : []
          content {
            name = "waha-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.waha_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Service for WAHA (ClusterIP)
resource "kubernetes_service" "waha" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# NodePort service for WAHA (for external access)
resource "kubernetes_service" "waha_nodeport" {
  metadata {
    name      = "${var.app_name}-nodeport"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      node_port   = var.node_port
      protocol    = "TCP"
    }
  }

  depends_on = [
    kubernetes_deployment.waha
  ]
}

# Horizontal Pod Autoscaler (optional)
resource "kubernetes_horizontal_pod_autoscaler_v2" "waha" {
  count = var.enable_autoscaling ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.waha.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.waha]
}

