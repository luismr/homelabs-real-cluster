output "namespace" {
  description = "Namespace for pudim.dev domain"
  value       = kubernetes_namespace.pudim_dev.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service for pudim.dev"
  value       = module.pudim_dev_calculator.service_name
}

output "site_url" {
  description = "URL for pudim.dev site"
  value       = "https://pudim.dev"
}

