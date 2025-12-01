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

output "forms_service_name" {
  description = "Service name for singularideas.com.br forms service"
  value       = try(module.singularideas_com_br_forms[0].service_name, null)
}

output "forms_deployment_name" {
  description = "Deployment name for singularideas.com.br forms service"
  value       = try(module.singularideas_com_br_forms[0].deployment_name, null)
}

output "forms_url" {
  description = "URL for singularideas.com.br forms service"
  value       = "https://forms.singularideas.com.br"
}

output "forms_internal_url" {
  description = "Internal Kubernetes service URL for singularideas.com.br forms service"
  value       = try("${module.singularideas_com_br_forms[0].service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}.svc.cluster.local", null)
}

output "forms_internal_url_short" {
  description = "Short internal Kubernetes service URL for singularideas.com.br forms service"
  value       = try("${module.singularideas_com_br_forms[0].service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}", null)
}

output "waha_service_name" {
  description = "Service name for singularideas.com.br WAHA service"
  value       = try(module.singularideas_com_br_waha[0].service_name, null)
}

output "waha_deployment_name" {
  description = "Deployment name for singularideas.com.br WAHA service"
  value       = try(module.singularideas_com_br_waha[0].deployment_name, null)
}

output "waha_url" {
  description = "URL for singularideas.com.br WAHA service"
  value       = "https://waha.singularideas.com.br"
}

output "waha_internal_url" {
  description = "Internal Kubernetes service URL for singularideas.com.br WAHA service"
  value       = try("${module.singularideas_com_br_waha[0].service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}.svc.cluster.local", null)
}

output "waha_internal_url_short" {
  description = "Short internal Kubernetes service URL for singularideas.com.br WAHA service"
  value       = try("${module.singularideas_com_br_waha[0].service_name}.${kubernetes_namespace.singularideas_com_br.metadata[0].name}", null)
}

output "waha_nodeport_url" {
  description = "NodePort URL for WAHA service (exposed like Grafana)"
  value       = try("http://<MASTER_IP>:30101", null)
}

