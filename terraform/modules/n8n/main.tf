# ConfigMap for n8n service environment variables
resource "kubernetes_config_map_v1" "n8n_config" {
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

  data = {
    GENERIC_TIMEZONE                      = var.n8n_timezone
    TZ                                    = var.n8n_timezone
    N8N_PORT                              = "5678"
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true"
    N8N_RUNNERS_ENABLED                   = "true"
    QUEUE_HEALTH_CHECK_ACTIVE             = "true"
    N8N_METRICS                           = "true"
  }
}

# PersistentVolumeClaim for n8n data
resource "kubernetes_persistent_volume_claim" "n8n_data" {
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

# Deployment for n8n service
resource "kubernetes_deployment" "n8n" {

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
    replicas = var.replicas

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
          image = var.n8n_image

          port {
            container_port = 5678
            protocol       = "TCP"
          }

          # Load environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.n8n_config.metadata[0].name
            }
          }

          # Mount persistent volume at /home/node/.n8n
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "n8n-data"
              mount_path = "/home/node/.n8n"
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
          for_each = var.enable_nfs ? [1] : []
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
}

# Service for n8n (ClusterIP)
resource "kubernetes_service" "n8n" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
    annotations = var.enable_cloudflare_tunnel ? {
      "cloudflare-tunnel/hostname" = var.domain
    } : {}
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = 5678
      target_port = 5678
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ServiceMonitor for Prometheus metrics scraping
resource "kubernetes_manifest" "n8n_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = var.app_name
      namespace = var.namespace
      labels = {
        app         = var.app_name
        domain      = var.domain
        environment = var.environment
        managed-by  = "terraform"
        release     = "kube-prometheus-stack" # Label to be discovered by Prometheus
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = var.app_name
        }
      }
      endpoints = [
        {
          port     = "http"
          interval = "30s"
          path     = "/metrics"
        },
      ]
    }
  }
}

