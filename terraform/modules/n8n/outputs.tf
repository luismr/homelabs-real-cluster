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

output "webhook_url" {
  description = "Webhook URL for n8n"
  value       = var.webhook_url
}

output "n8n_host" {
  description = "Hostname for n8n"
  value       = var.n8n_host
}

output "n8n_protocol" {
  description = "Protocol for n8n (http/https)"
  value       = var.n8n_protocol
}

output "webhook_full_url" {
  description = "Full webhook URL (protocol + host)"
  value       = var.webhook_url != null && var.n8n_protocol != null ? "${var.n8n_protocol}://${var.webhook_url}" : null
}

