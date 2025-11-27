output "namespace" {
  description = "Namespace for singularideas.com.br domain"
  value       = kubernetes_namespace.singularideas_com_br.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service for singularideas.com.br"
  value       = module.singularideas_com_br_site.service_name
}

output "site_url" {
  description = "URL for singularideas.com.br site"
  value       = "https://singularideas.com.br"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for singularideas.com.br"
  value       = "${module.singularideas_com_br_site.service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for singularideas.com.br"
  value       = "${module.singularideas_com_br_site.service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}"
}

