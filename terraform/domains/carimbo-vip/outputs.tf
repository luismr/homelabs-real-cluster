output "namespace" {
  description = "Namespace for carimbo.vip domain"
  value       = kubernetes_namespace.carimbo_vip.metadata[0].name
}

output "service_name" {
  description = "Service name for carimbo.vip site"
  value       = module.carimbo_vip_site.service_name
}

output "site_url" {
  description = "URL for carimbo.vip site"
  value       = "https://carimbo.vip"
}

