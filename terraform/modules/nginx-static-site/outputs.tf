output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.site.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.site.metadata[0].name
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the site"
  value       = var.domain
}

output "pvc_name" {
  description = "Name of the PersistentVolumeClaim (if NFS enabled)"
  value       = var.enable_nfs ? kubernetes_persistent_volume_claim.site_content[0].metadata[0].name : null
}

