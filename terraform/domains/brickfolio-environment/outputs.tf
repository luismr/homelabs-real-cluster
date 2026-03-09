output "namespace" {
  description = "Namespace for this brickfolio environment"
  value       = kubernetes_namespace.brickfolio_env.metadata[0].name
}

output "api_service_name" {
  description = "API Kubernetes service name"
  value       = module.api.service_name
}

output "app_service_name" {
  description = "App Kubernetes service name"
  value       = module.app.service_name
}

output "api_url" {
  description = "Public URL for the API"
  value       = "https://api.${var.environment}.brickfolio.online"
}

output "app_url" {
  description = "Public URL for the App"
  value       = "https://app.${var.environment}.brickfolio.online"
}

output "api_internal_url" {
  description = "Internal Kubernetes service URL for the API"
  value       = "${module.api.service_name}.${kubernetes_namespace.brickfolio_env.metadata[0].name}.svc.cluster.local"
}

output "app_internal_url" {
  description = "Internal Kubernetes service URL for the App"
  value       = "${module.app.service_name}.${kubernetes_namespace.brickfolio_env.metadata[0].name}.svc.cluster.local"
}

output "redis_service_name" {
  description = "Redis Kubernetes service name"
  value       = module.redis.service_name
}

output "postgres_service_name" {
  description = "PostgreSQL Kubernetes service name"
  value       = module.postgres.service_name
}
