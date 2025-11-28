output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.app.metadata[0].name
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.app.metadata[0].name
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the application"
  value       = var.domain
}
