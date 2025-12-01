output "service_name" {
  description = "The name of the Kubernetes service"
  value       = module.forms_app.service_name
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = module.forms_app.deployment_name
}

output "config_map_name" {
  description = "The name of the ConfigMap"
  value       = kubernetes_config_map_v1.forms_config.metadata[0].name
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the forms service"
  value       = var.domain
}

