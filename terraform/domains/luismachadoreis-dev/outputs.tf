output "namespace" {
  description = "Namespace for luismachadoreis.dev domain"
  value       = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
}

output "service_name" {
  description = "Service name for luismachadoreis.dev site"
  value       = module.luismachadoreis_dev_site.service_name
}

output "site_url" {
  description = "URL for luismachadoreis.dev site"
  value       = "https://luismachadoreis.dev"
}

