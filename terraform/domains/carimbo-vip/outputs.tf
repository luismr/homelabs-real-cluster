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

output "forms_service_name" {
  description = "Service name for carimbo.vip forms service"
  value       = try(module.carimbo_vip_forms[0].service_name, null)
}

output "forms_deployment_name" {
  description = "Deployment name for carimbo.vip forms service"
  value       = try(module.carimbo_vip_forms[0].deployment_name, null)
}

output "forms_url" {
  description = "URL for carimbo.vip forms service"
  value       = "https://forms.carimbo.vip"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for carimbo.vip site"
  value       = "${module.carimbo_vip_site.service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for carimbo.vip site"
  value       = "${module.carimbo_vip_site.service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}"
}

output "forms_internal_url" {
  description = "Internal Kubernetes service URL for carimbo.vip forms service"
  value       = try("${module.carimbo_vip_forms[0].service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}.svc.cluster.local", null)
}

output "forms_internal_url_short" {
  description = "Short internal Kubernetes service URL for carimbo.vip forms service"
  value       = try("${module.carimbo_vip_forms[0].service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}", null)
}

output "waha_service_name" {
  description = "Service name for carimbo.vip WAHA service"
  value       = try(module.carimbo_vip_waha[0].service_name, null)
}

output "waha_deployment_name" {
  description = "Deployment name for carimbo.vip WAHA service"
  value       = try(module.carimbo_vip_waha[0].deployment_name, null)
}

output "waha_url" {
  description = "URL for carimbo.vip WAHA service"
  value       = "https://waha.carimbo.vip"
}

output "waha_internal_url" {
  description = "Internal Kubernetes service URL for carimbo.vip WAHA service"
  value       = try("${module.carimbo_vip_waha[0].service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}.svc.cluster.local", null)
}

output "waha_internal_url_short" {
  description = "Short internal Kubernetes service URL for carimbo.vip WAHA service"
  value       = try("${module.carimbo_vip_waha[0].service_name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}", null)
}

output "waha_nodeport_url" {
  description = "NodePort URL for WAHA service (exposed like Grafana)"
  value       = try("http://<MASTER_IP>:30100", null)
}

# n8n outputs
output "n8n_service_name" {
  description = "Service name for carimbo.vip n8n service"
  value       = try(kubernetes_service.n8n[0].metadata[0].name, null)
}

output "n8n_deployment_name" {
  description = "Deployment name for carimbo.vip n8n service"
  value       = try(kubernetes_deployment.n8n[0].metadata[0].name, null)
}

output "n8n_internal_url" {
  description = "Internal Kubernetes service URL for carimbo.vip n8n service"
  value       = try("${kubernetes_service.n8n[0].metadata[0].name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}.svc.cluster.local:5678", null)
}

output "n8n_internal_url_short" {
  description = "Short internal Kubernetes service URL for carimbo.vip n8n service"
  value       = try("${kubernetes_service.n8n[0].metadata[0].name}.${kubernetes_namespace.carimbo_vip.metadata[0].name}:5678", null)
}

