output "deployment_name" {
  description = "Name of the Cloudflare Tunnel deployment"
  value       = kubernetes_deployment.tunnel.metadata[0].name
}

output "service_name" {
  description = "Name of the metrics service"
  value       = kubernetes_service.tunnel_metrics.metadata[0].name
}

output "namespace" {
  description = "Namespace where tunnel is deployed"
  value       = var.namespace
}

