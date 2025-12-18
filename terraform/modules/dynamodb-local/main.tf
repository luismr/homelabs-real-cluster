# PersistentVolumeClaim for DynamoDB Local data
resource "kubernetes_persistent_volume_claim" "dynamodb_data" {
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

# Deployment for DynamoDB Local service
resource "kubernetes_deployment" "dynamodb_local" {
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
          image = var.dynamodb_image

          port {
            container_port = 8000
            protocol       = "TCP"
          }

          # Mount persistent volume at /home/dynamodblocal/data
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "dynamodb-data"
              mount_path = "/home/dynamodblocal/data"
            }
          }

          # DynamoDB Local command arguments
          command = var.enable_nfs ? [
            "java",
            "-Djava.library.path=./DynamoDBLocal_lib",
            "-jar",
            "DynamoDBLocal.jar",
            "-sharedDb",
            "-dbPath",
            "/home/dynamodblocal/data"
          ] : [
            "java",
            "-Djava.library.path=./DynamoDBLocal_lib",
            "-jar",
            "DynamoDBLocal.jar",
            "-sharedDb"
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
            tcp_socket {
              port = 8000
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 8000
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
            name = "dynamodb-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.dynamodb_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Service for DynamoDB Local (ClusterIP)
resource "kubernetes_service" "dynamodb_local" {
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
      name        = "dynamodb"
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

