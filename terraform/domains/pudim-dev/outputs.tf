output "namespace" {
  description = "Namespace for pudim.dev domain"
  value       = kubernetes_namespace.pudim_dev.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service for pudim.dev"
  value       = module.pudim_dev_calculator.service_name
}

output "redis_service_name" {
  description = "Name of the Redis service for pudim.dev calculator cache"
  value       = module.pudim_dev_redis.service_name
}

output "redis_url" {
  description = "In-cluster Redis URL for pudim.dev calculator cache"
  value       = "redis://${module.pudim_dev_redis.service_name}:6379"
}

output "site_url" {
  description = "URL for pudim.dev site"
  value       = "https://pudim.dev"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for pudim.dev"
  value       = "${module.pudim_dev_calculator.service_name}.${kubernetes_namespace.pudim_dev.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for pudim.dev"
  value       = "${module.pudim_dev_calculator.service_name}.${kubernetes_namespace.pudim_dev.metadata[0].name}"
}

