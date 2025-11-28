output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.redis.metadata[0].name
}

output "service_port" {
  description = "The port of the Redis service"
  value       = 6379
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.redis.metadata[0].name
}

output "pvc_name" {
  description = "The name of the PersistentVolumeClaim (if enabled)"
  value       = var.enable_nfs ? kubernetes_persistent_volume_claim.redis_data[0].metadata[0].name : null
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the Redis service"
  value       = var.domain
}

output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.redis.metadata[0].name
}

output "service_port" {
  description = "The port of the Redis service"
  value       = 6379
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.redis.metadata[0].name
}

output "config_map_name" {
  description = "The name of the ConfigMap"
  value       = kubernetes_config_map_v1.redis_config.metadata[0].name
}

output "pvc_name" {
  description = "The name of the PersistentVolumeClaim (if enabled)"
  value       = var.enable_nfs ? kubernetes_persistent_volume_claim.redis_data[0].metadata[0].name : null
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the Redis service"
  value       = var.domain
}

