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
      ], var.maxmemory != null ? ["maxmemory ${var.maxmemory}"] : [], var.requirepass != null ? ["requirepass ${var.requirepass}"] : [], length(var.acl_users) > 0 ? concat(
      ["# ACL Users"],
      [for user in var.acl_users : "user ${user.username} on >${user.password} ~${user.keys} ${user.commands}"]
    ) : []))
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

        # Redis Exporter sidecar container for Prometheus metrics
        container {
          name  = "redis-exporter"
          image = "oliver006/redis_exporter:latest"

          port {
            name           = "metrics"
            container_port = 9121
            protocol       = "TCP"
          }

          env {
            name  = "REDIS_ADDR"
            value = "redis://localhost:6379"
          }

          dynamic "env" {
            for_each = var.requirepass != null ? [1] : []
            content {
              name  = "REDIS_PASSWORD"
              value = var.requirepass
            }
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
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

    port {
      name        = "metrics"
      port        = 9121
      target_port = 9121
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ServiceMonitor for Prometheus to scrape Redis metrics
# Only create if ServiceMonitor CRD exists (monitoring stack installed)
# Note: This resource will fail during plan if CRD doesn't exist yet
# Ensure monitoring stack is installed first: terraform apply -target=module.monitoring
resource "kubernetes_manifest" "redis_servicemonitor" {
  count = var.enable_servicemonitor ? 1 : 0

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
        release     = "kube-prometheus-stack"
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
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  }

  computed_fields = ["metadata.labels", "metadata.annotations"]

  depends_on = [kubernetes_service.redis]
}
