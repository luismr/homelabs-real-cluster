output "namespace" {
  description = "Namespace for ligflat.com.br domain"
  value       = kubernetes_namespace.ligflat_com_br.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service for ligflat.com.br"
  value       = module.ligflat_com_br_site.service_name
}

output "site_url" {
  description = "URL for ligflat.com.br site"
  value       = "https://ligflat.com.br"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for ligflat.com.br"
  value       = "${module.ligflat_com_br_site.service_name}.${kubernetes_namespace.ligflat_com_br.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for ligflat.com.br"
  value       = "${module.ligflat_com_br_site.service_name}.${kubernetes_namespace.ligflat_com_br.metadata[0].name}"
}

