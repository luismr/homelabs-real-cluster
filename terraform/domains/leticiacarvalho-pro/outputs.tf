output "namespace" {
  description = "Namespace for leticiacarvalho.pro domain"
  value       = kubernetes_namespace.leticiacarvalho_pro.metadata[0].name
}

output "service_name" {
  description = "Service name for leticiacarvalho.pro site"
  value       = module.leticiacarvalho_pro_site.service_name
}

output "site_url" {
  description = "URL for leticiacarvalho.pro site"
  value       = "https://leticiacarvalho.pro"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for leticiacarvalho.pro site"
  value       = "${module.leticiacarvalho_pro_site.service_name}.${kubernetes_namespace.leticiacarvalho_pro.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for leticiacarvalho.pro site"
  value       = "${module.leticiacarvalho_pro_site.service_name}.${kubernetes_namespace.leticiacarvalho_pro.metadata[0].name}"
}

