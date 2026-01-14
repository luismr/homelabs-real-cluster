# ConfigMap for PostgreSQL pg_hba.conf to allow connections from cluster network and external
resource "kubernetes_config_map_v1" "postgres_pg_hba" {
  metadata {
    name      = "${var.app_name}-pg-hba"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    "pg_hba.conf" = <<-EOT
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      # IPv4 local connections:
      host    all             all             127.0.0.1/32            scram-sha-256
      # IPv6 local connections:
      host    all             all             ::1/128                 scram-sha-256
      # Kubernetes cluster network (k3s default: 10.42.0.0/16)
      host    all             all             10.42.0.0/16           scram-sha-256
      # Allow connections from any IP (for NodePort access)
      host    all             all             0.0.0.0/0               scram-sha-256
      # Allow local connections without password (for initialization)
      local   all             all                                     trust
    EOT
  }
}

# ConfigMap for PostgreSQL initialization script to enable pgvector
# This script runs automatically when PostgreSQL initializes a new data directory
resource "kubernetes_config_map_v1" "postgres_init" {
  count = var.enable_pgvector ? 1 : 0

  metadata {
    name      = "${var.app_name}-init"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  data = {
    "01-init-pgvector.sql" = <<-EOT
      -- Enable pgvector extension in the current database
      CREATE EXTENSION IF NOT EXISTS vector;
    EOT
    "02-update-pg-hba.sh"  = <<-EOT
      #!/bin/bash
      set -e
      # This script runs after PostgreSQL initializes to update pg_hba.conf
      # Wait for PostgreSQL to be ready
      until pg_isready -U ${var.postgres_user} -d postgres; do
        sleep 2
      done
      
      # Update pg_hba.conf to allow cluster network and external connections
      if [ -f /var/lib/postgresql/data/pg_hba.conf ]; then
        # Backup original
        cp /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf.bak
        
        # Add cluster network and external access if not present
        if ! grep -q "10.42.0.0/16" /var/lib/postgresql/data/pg_hba.conf; then
          echo "host    all             all             10.42.0.0/16           scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
        fi
        if ! grep -q "0.0.0.0/0" /var/lib/postgresql/data/pg_hba.conf; then
          echo "host    all             all             0.0.0.0/0               scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
        fi
        
        # Reload PostgreSQL configuration
        psql -U ${var.postgres_user} -d postgres -c "SELECT pg_reload_conf();" || true
      fi
    EOT
  }
}

# Secret for PostgreSQL password
resource "kubernetes_secret_v1" "postgres_password" {
  count = var.postgres_password != null ? 1 : 0

  metadata {
    name      = "${var.app_name}-password"
    namespace = var.namespace
    labels = {
      app         = var.app_name
      domain      = var.domain
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  type = "Opaque"

  data = {
    password = base64encode(var.postgres_password)
  }
}

# PersistentVolumeClaim for PostgreSQL data
resource "kubernetes_persistent_volume_claim" "postgres_data" {
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

# Deployment for PostgreSQL service
resource "kubernetes_deployment" "postgres" {
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
    replicas                 = var.replicas
    progress_deadline_seconds = 1800  # 30 minutes (default is 600s)

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

        # Init container to copy pg_hba.conf template (will be used if data directory is empty)
        init_container {
          name  = "init-pg-hba"
          image = "busybox:latest"

          command = [
            "sh",
            "-c",
            <<-EOT
              # If data directory exists and is empty, copy our pg_hba.conf template
              # If data directory has files but no PG_VERSION, it's a partial/invalid state - clean it
              if [ -d /var/lib/postgresql/data ]; then
                if [ ! "$(ls -A /var/lib/postgresql/data)" ]; then
                  # Empty directory - copy template
                  cp /pg-hba-config/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
                  chmod 600 /var/lib/postgresql/data/pg_hba.conf
                elif [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
                  # Directory has files but no PG_VERSION - invalid state, clean it
                  echo "Warning: Data directory exists but is not a valid PostgreSQL data directory. Cleaning..."
                  rm -rf /var/lib/postgresql/data/*
                  cp /pg-hba-config/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
                  chmod 600 /var/lib/postgresql/data/pg_hba.conf
                fi
              fi
            EOT
          ]

          volume_mount {
            name       = "pg-hba-config"
            mount_path = "/pg-hba-config"
            read_only  = true
          }

          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "postgres-data"
              mount_path = "/var/lib/postgresql/data"
            }
          }
        }

        container {
          name  = var.app_name
          image = var.postgres_image

          port {
            container_port = 5432
            protocol       = "TCP"
          }

          # Mount persistent volume at /var/lib/postgresql/data
          dynamic "volume_mount" {
            for_each = var.enable_nfs ? [1] : []
            content {
              name       = "postgres-data"
              mount_path = "/var/lib/postgresql/data"
            }
          }

          # Mount init scripts for pgvector (PostgreSQL runs scripts in /docker-entrypoint-initdb.d/ on first init)
          dynamic "volume_mount" {
            for_each = var.enable_pgvector ? [1] : []
            content {
              name       = "init-scripts"
              mount_path = "/docker-entrypoint-initdb.d"
              read_only  = true
            }
          }

          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }

          env {
            name  = "POSTGRES_DB"
            value = coalesce(var.database_name, "postgres")
          }

          dynamic "env" {
            for_each = var.postgres_password != null ? [1] : []
            content {
              name = "POSTGRES_PASSWORD"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret_v1.postgres_password[0].metadata[0].name
                  key  = "password"
                }
              }
            }
          }

          # Configure PostgreSQL to allow connections from any host
          # This is needed for Kubernetes cluster network and NodePort access
          env {
            name  = "POSTGRES_HOST_AUTH_METHOD"
            value = "scram-sha-256"
          }

          # Additional PostgreSQL environment variables
          dynamic "env" {
            for_each = var.postgres_env_vars
            content {
              name  = env.key
              value = env.value
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
            exec {
              command = [
                "pg_isready",
                "-U", var.postgres_user
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
                "pg_isready",
                "-U", var.postgres_user
              ]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Lifecycle hook to update pg_hba.conf after container starts
          lifecycle {
            post_start {
              exec {
                command = [
                  "sh",
                  "-c",
                  <<-EOT
                    # Wait for PostgreSQL to be ready
                    until pg_isready -U ${var.postgres_user}; do sleep 1; done
                    # Update pg_hba.conf to allow cluster network and external connections
                    if [ -f /var/lib/postgresql/data/pg_hba.conf ]; then
                      # Add cluster network access if not present
                      if ! grep -q "10.42.0.0/16" /var/lib/postgresql/data/pg_hba.conf; then
                        echo "host    all             all             10.42.0.0/16           scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
                      fi
                      # Add external access if not present
                      if ! grep -q "0.0.0.0/0" /var/lib/postgresql/data/pg_hba.conf; then
                        echo "host    all             all             0.0.0.0/0               scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf
                      fi
                      # Reload PostgreSQL configuration
                      psql -U ${var.postgres_user} -c "SELECT pg_reload_conf();" || true
                    fi
                  EOT
                ]
              }
            }
          }
        }

        # PostgreSQL Exporter sidecar container for Prometheus metrics
        container {
          name  = "postgres-exporter"
          image = "quay.io/prometheuscommunity/postgres-exporter:latest"

          port {
            name           = "metrics"
            container_port = 9187
            protocol       = "TCP"
          }

          env {
            name  = "DATA_SOURCE_URI"
            value = "localhost:5432/${coalesce(var.database_name, "postgres")}?sslmode=disable"
          }

          env {
            name  = "DATA_SOURCE_USER"
            value = var.postgres_user
          }

          dynamic "env" {
            for_each = var.postgres_password != null ? [1] : []
            content {
              name = "DATA_SOURCE_PASS"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret_v1.postgres_password[0].metadata[0].name
                  key  = "password"
                }
              }
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

        # pg_hba.conf ConfigMap volume
        volume {
          name = "pg-hba-config"
          config_map {
            name = kubernetes_config_map_v1.postgres_pg_hba.metadata[0].name
          }
        }

        # Init scripts volume (for pgvector initialization)
        # PostgreSQL Docker images automatically run .sql files in /docker-entrypoint-initdb.d/
        dynamic "volume" {
          for_each = var.enable_pgvector ? [1] : []
          content {
            name = "init-scripts"
            config_map {
              name = kubernetes_config_map_v1.postgres_init[0].metadata[0].name
            }
          }
        }

        # Data volume only when NFS is enabled
        dynamic "volume" {
          for_each = var.enable_nfs ? [1] : []
          content {
            name = "postgres-data"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.postgres_data[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

# Service for PostgreSQL (ClusterIP)
resource "kubernetes_service" "postgres" {
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
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    port {
      name        = "metrics"
      port        = 9187
      target_port = 9187
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# NodePort service for PostgreSQL (for external access like Grafana)
resource "kubernetes_service" "postgres_nodeport" {
  count = var.node_port != null ? 1 : 0

  depends_on = [var.depends_on_resources]

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
      name        = "postgres"
      port        = 5432
      target_port = 5432
      node_port   = var.node_port
      protocol    = "TCP"
    }
  }
}

# ServiceMonitor for Prometheus to scrape PostgreSQL metrics
# Only create if ServiceMonitor CRD exists (monitoring stack installed)
# Note: This resource will fail during plan if CRD doesn't exist yet
# Ensure monitoring stack is installed first: terraform apply -target=module.monitoring
resource "kubernetes_manifest" "postgres_servicemonitor" {
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

  depends_on = [kubernetes_service.postgres]
}

