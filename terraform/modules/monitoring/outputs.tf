output "namespace" {
  description = "The namespace where monitoring stack is deployed"
  value       = var.namespace
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://<MASTER_IP>:${var.grafana_node_port}"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://<MASTER_IP>:${var.prometheus_node_port}"
}

output "alertmanager_url" {
  description = "URL to access Alertmanager"
  value       = "http://<MASTER_IP>:${var.alertmanager_node_port}"
}

output "loki_service" {
  description = "Loki service name"
  value       = "loki"
}

output "loki_namespace" {
  description = "Namespace where Loki is deployed"
  value       = var.namespace
}

output "prometheus_operator_ready" {
  description = "Indicates that Prometheus Operator (and ServiceMonitor CRD) is ready"
  value       = helm_release.kube_prometheus_stack.status
}

