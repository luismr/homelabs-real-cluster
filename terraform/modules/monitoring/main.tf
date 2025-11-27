# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name       = "monitoring"
      managed-by = "terraform"
    }
  }
}

# Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = var.namespace
  version    = "61.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes      = ["ReadWriteOnce"]
                storageClassName = var.enable_nfs_storage ? var.storage_class : null
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
        service = {
          type     = "NodePort"
          nodePort = var.prometheus_node_port
        }
      }
      grafana = {
        adminPassword = var.grafana_admin_password
        service = {
          type     = "NodePort"
          nodePort = var.grafana_node_port
        }
        persistence = {
          enabled     = var.enable_nfs_storage
          storageClassName = var.enable_nfs_storage ? var.storage_class : null
          size        = "10Gi"
          accessModes = ["ReadWriteOnce"]
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes      = ["ReadWriteOnce"]
                storageClassName = var.enable_nfs_storage ? var.storage_class : null
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          }
        }
        service = {
          type     = "NodePort"
          nodePort = var.alertmanager_node_port
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# Install Loki with NFS storage and Promtail configured for all namespaces
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = var.namespace
  version    = "2.9.11"
  force_update = true

  values = [
    yamlencode({
      loki = {
        enabled = true
        persistence = {
          enabled         = var.enable_nfs_storage
          storageClassName = var.enable_nfs_storage ? var.storage_class : null
          size            = var.loki_storage_size
          accessModes     = ["ReadWriteOnce"]
        }
        # Let Helm chart use default config - it will work correctly
        # Custom config was causing issues with invalid fields
      }
      promtail = {
        enabled = true

        # Use default k8s scrape configs (all namespaces, containers stdout/stderr)
        # and inject common pipeline stages via snippets
        config = {
          snippets = {
            pipelineStages = [
              # 1) Strip Kubernetes/containerd CRI wrapper so .log is just the app line
              {
                cri = {}
              },
              # 2) Drop empty lines
              {
                drop = {
                  expression = "^$"
                }
              },
              # 3) Try to parse JSON logs (Node, Spring, Nginx in JSON)
              {
                json = {
                  source = "log"
                  # Keep generic; apps can have slightly different fields
                  expressions = {
                    timestamp = "timestamp"
                    time      = "time"
                    level     = "level"
                    msg       = "msg"
                    message   = "message"
                    method    = "method"
                    path      = "path"
                    ip        = "ip"
                    origin    = "origin"
                    userAgent = "userAgent"
                    name      = "name"
                    email     = "email"
                    hasMobile = "hasMobile"
                    hasMessage = "hasMessage"
                    statusCode = "statusCode"
                    duration   = "duration"
                  }
                }
              },
              # 4) Use app-provided time/timestamp if present
              {
                timestamp = {
                  source = "timestamp"
                  format = "RFC3339"
                }
              },
              {
                timestamp = {
                  source = "time"
                  # if you use unix ms in Node (e.g. pino) change to UnixMs
                  format = "RFC3339"
                }
              },
              # 5) Extract level as label (from JSON field extracted in step 3)
              {
                labels = {
                  level = ""
                }
              }
            ]
          }

          # Labels (app, container, namespace, job, filename) are set by Helm chart defaults
          # via relabel_configs in the default scrape configs. To customize, uncomment below:
          # extraScrapeConfigs = <<-EOT
          # - job_name: kubernetes-pods
          #   kubernetes_sd_configs:
          #   - role: pod
          #   relabel_configs:
          #   # Extract namespace label
          #   - source_labels: [__meta_kubernetes_namespace]
          #     target_label: namespace
          #   # Extract container name
          #   - source_labels: [__meta_kubernetes_pod_container_name]
          #     target_label: container
          #   # Extract app label from pod labels
          #   - source_labels: [__meta_kubernetes_pod_label_app]
          #     target_label: app
          #   # Extract app.kubernetes.io/name label (alternative)
          #   - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
          #     target_label: app
          #   # Set job name
          #   - target_label: job
          #     replacement: kubernetes-pods
          #   # filename is automatically set by Promtail from __path__
          # EOT
        }
      }
      grafana = {
        enabled = false
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.kube_prometheus_stack
  ]
}

# Configure Loki datasource in Grafana
resource "kubernetes_config_map" "loki_datasource" {
  metadata {
    name      = "loki-datasource"
    namespace = var.namespace
    labels = {
      app        = "grafana"
      managed-by = "terraform"
    }
  }

  data = {
    "loki-datasource.yaml" = <<-EOF
      apiVersion: 1
      datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki:3100
        version: 1
        isDefault: false
        jsonData:
          maxLines: 1000
      EOF
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

