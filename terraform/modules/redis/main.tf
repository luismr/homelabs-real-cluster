resource "kubernetes_persistent_volume_claim" "redis_data" {
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
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

resource "kubernetes_deployment" "redis" {
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
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name != null ? [1] : []
          content {
            name = var.image_pull_secret_name
          }
        }

        container {
          name  = var.app_name
          image = var.redis_image

          port {
            container_port = 6379
            protocol       = "TCP"
          }

          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "redis-data"
              mount_path = "/data"
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
        }

        dynamic "volume" {
          for_each = var.enable_nfs ? [1] : []
          content {
            name = "redis-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.redis_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
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
    selector = {
      app = var.app_name
    }

    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ConfigMap for Redis configuration
resource "kubernetes_config_map_v1" "redis_config" {
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
    # Enable RDB persistence (snapshots)
    # Save the dataset to disk every 60 seconds if at least 1000 keys changed
    "redis.conf" = join("\n", concat([
      "# Persistence configuration",
      "save 60 1000",
      "save 300 100",
      "save 900 1",
      "",
      "# Data directory",
      "dir /data",
      "",
      "# RDB filename",
      "dbfilename dump.rdb",
      "",
      "# Append only file (AOF) - optional, disabled by default",
      "# appendonly yes",
      "# appendfsync everysec",
      "",
      "# Memory and performance",
      "maxmemory-policy ${var.maxmemory_policy}",
      "",
      "# Network",
      "bind 0.0.0.0",
      "protected-mode ${var.protected_mode ? "yes" : "no"}",
    ], var.maxmemory != null ? ["maxmemory ${var.maxmemory}"] : [], var.requirepass != null ? ["requirepass ${var.requirepass}"] : []))
  }
}

# PersistentVolumeClaim for Redis data
resource "kubernetes_persistent_volume_claim" "redis_data" {
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
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

# Deployment for Redis service
resource "kubernetes_deployment" "redis" {
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
          image = var.redis_image

          port {
            container_port = 6379
            protocol       = "TCP"
          }

          # Mount Redis configuration
          volume_mount {
            name       = "redis-config"
            mount_path = "/etc/redis"
            read_only  = true
          }

          # Mount persistent volume at /data
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "redis-data"
              mount_path = "/data"
            }
          }

          # Command to use custom config file
          command = [
            "redis-server",
            "/etc/redis/redis.conf"
          ]

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
            exec {
              command = [
                "redis-cli",
                "ping"
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = [
                "redis-cli",
                "ping"
              ]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        # ConfigMap volume for Redis configuration
        volume {
          name = "redis-config"
          config_map {
            name = kubernetes_config_map_v1.redis_config.metadata[0].name
          }
        }

        # Data volume only when NFS is enabled
        dynamic "volume" {
          for_each = var.enable_nfs ? [1] : []
          content {
            name = "redis-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.redis_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Service for Redis (ClusterIP)
resource "kubernetes_service" "redis" {
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
    selector = {
      app = var.app_name
    }

    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

