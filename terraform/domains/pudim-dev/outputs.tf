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

# Redis Configuration Outputs
output "redis" {
  description = "Redis configuration for pudim.dev calculator"
  value = {
    enabled                     = var.redis_enabled
    service_name                = module.pudim_dev_redis.service_name
    url                         = "redis://${module.pudim_dev_redis.service_name}:6379"
    prefix                      = var.redis_prefix
    ttl                         = var.redis_ttl
    circuit_breaker_cooldown_ms = var.redis_circuit_breaker_cooldown_ms
    maxmemory                   = var.redis_maxmemory
    maxmemory_policy            = var.redis_maxmemory_policy
    deployment_name             = module.pudim_dev_redis.deployment_name
    namespace                   = module.pudim_dev_redis.namespace
  }
}

# DynamoDB Configuration Outputs
output "dynamodb" {
  description = "DynamoDB configuration for pudim.dev calculator"
  value = {
    enabled                     = var.dynamodb_enabled
    endpoint                    = var.dynamodb_enabled ? coalesce(var.dynamodb_endpoint, module.pudim_dev_dynamodb_local.service_url) : null
    circuit_breaker_cooldown_ms = var.dynamodb_enabled ? var.dynamodb_circuit_breaker_cooldown_ms : null
    aws_region                  = var.dynamodb_enabled ? var.dynamodb_aws_region : null
    aws_access_key_id           = var.dynamodb_enabled ? var.dynamodb_aws_access_key_id : null
    aws_secret_access_key       = var.dynamodb_enabled ? var.dynamodb_aws_secret_access_key : null
    service_name                = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.service_name : null
    service_url                 = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.service_url : null
    service_port                = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.service_port : null
    deployment_name             = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.deployment_name : null
    namespace                   = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.namespace : null
    pvc_name                    = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.pvc_name : null
    domain                      = var.dynamodb_enabled ? module.pudim_dev_dynamodb_local.domain : null
  }
}

# Leaderboard Configuration Outputs
output "leaderboard" {
  description = "Leaderboard configuration for pudim.dev calculator"
  value = {
    enabled = var.leaderboard_enabled
  }
}

