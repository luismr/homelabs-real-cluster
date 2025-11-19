# PersistentVolumeClaim for app data (optional)
resource "kubernetes_persistent_volume_claim" "app_data" {
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

# Deployment
resource "kubernetes_deployment" "app" {
  depends_on = [var.depends_on_resources]
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
    replicas = var.enable_autoscaling ? null : var.replicas

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
          image = var.app_image

          port {
            container_port = var.container_port
            protocol       = "TCP"
          }

          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "data"
              mount_path = "/data" # Generic mount path
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
              path = var.health_check_path
              port = coalesce(var.health_check_port, var.container_port)
            }
            initial_delay_seconds = var.health_check_initial_delay
            period_seconds        = var.health_check_period
          }

          readiness_probe {
            http_get {
              path = var.health_check_path
              port = coalesce(var.health_check_port, var.container_port)
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        # Data volume only when NFS is enabled
        dynamic "volume" {
          for_each = var.enable_nfs ? [1] : []
          content {
            name = "data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.app_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Service for the application
resource "kubernetes_service" "app" {
  depends_on = [var.depends_on_resources]
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
    annotations = {
      "cloudflare-tunnel/hostname" = var.domain
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Horizontal Pod Autoscaler (optional)
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
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
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.cpu_target_percentage
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.memory_target_percentage
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.app]
}
