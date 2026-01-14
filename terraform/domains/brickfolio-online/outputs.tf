output "namespace" {
  description = "Namespace for brickfolio.online domain"
  value       = kubernetes_namespace.brickfolio_online.metadata[0].name
}

output "service_name" {
  description = "Service name for brickfolio.online site"
  value       = module.brickfolio_online_site.service_name
}

output "site_url" {
  description = "URL for brickfolio.online site"
  value       = "https://brickfolio.online"
}

output "forms_service_name" {
  description = "Service name for brickfolio.online forms service"
  value       = try(module.brickfolio_online_forms[0].service_name, null)
}

output "forms_deployment_name" {
  description = "Deployment name for brickfolio.online forms service"
  value       = try(module.brickfolio_online_forms[0].deployment_name, null)
}

output "forms_url" {
  description = "URL for brickfolio.online forms service"
  value       = "https://forms.brickfolio.online"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for brickfolio.online site"
  value       = "${module.brickfolio_online_site.service_name}.${kubernetes_namespace.brickfolio_online.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for brickfolio.online site"
  value       = "${module.brickfolio_online_site.service_name}.${kubernetes_namespace.brickfolio_online.metadata[0].name}"
}

output "forms_internal_url" {
  description = "Internal Kubernetes service URL for brickfolio.online forms service"
  value       = try("${module.brickfolio_online_forms[0].service_name}.${kubernetes_namespace.brickfolio_online.metadata[0].name}.svc.cluster.local", null)
}

output "forms_internal_url_short" {
  description = "Short internal Kubernetes service URL for brickfolio.online forms service"
  value       = try("${module.brickfolio_online_forms[0].service_name}.${kubernetes_namespace.brickfolio_online.metadata[0].name}", null)
}
