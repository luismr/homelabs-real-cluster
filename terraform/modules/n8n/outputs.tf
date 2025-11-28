output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.n8n.metadata[0].name
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.n8n.metadata[0].name
}

output "config_map_name" {
  description = "The name of the ConfigMap"
  value       = kubernetes_config_map_v1.n8n_config.metadata[0].name
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the n8n service"
  value       = var.domain
}

