variable "enable_nfs_storage" {
  description = "Enable NFS persistent storage"
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "nfs-client"
}

variable "site_image" {
  description = "Container image to deploy for this site"
  type        = string
  default     = null
}

variable "ghcr_username" {
  description = "GitHub username (or org) for GHCR auth"
  type        = string
  default     = null
}

variable "ghcr_token" {
  description = "GitHub token with read:packages for GHCR"
  type        = string
  sensitive   = true
  default     = null
}

variable "redis_enabled" {
  description = "Enable Redis caching for pudim-dev-calculator"
  type        = bool
  default     = true
}

variable "redis_prefix" {
  description = "Redis key prefix for pudim-dev-calculator"
  type        = string
  default     = "pudim:"
}

variable "redis_ttl" {
  description = "Redis TTL (seconds) for pudim-dev-calculator cache"
  type        = number
  default     = 3600
}

variable "redis_circuit_breaker_cooldown_ms" {
  description = "Redis circuit breaker cooldown (ms) for pudim-dev-calculator"
  type        = number
  default     = 60000
}

variable "redis_maxmemory" {
  description = "Redis maxmemory value (e.g., '128mb'). Set null to omit and rely on container memory limit."
  type        = string
  default     = "128mb"
}

variable "redis_maxmemory_policy" {
  description = "Redis maxmemory eviction policy"
  type        = string
  default     = "allkeys-lru"
}

variable "dynamodb_enabled" {
  description = "Enable DynamoDB for pudim-dev-calculator"
  type        = bool
  default     = false
}

variable "dynamodb_endpoint" {
  description = "DynamoDB endpoint URL (for local use DynamoDB Local service URL, omit for AWS)"
  type        = string
  default     = null
}

variable "dynamodb_circuit_breaker_cooldown_ms" {
  description = "DynamoDB circuit breaker cooldown (ms) for pudim-dev-calculator"
  type        = number
  default     = 300000
}

variable "dynamodb_aws_region" {
  description = "AWS region for DynamoDB (use 'us-east-1' for local DynamoDB Local)"
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_aws_access_key_id" {
  description = "AWS access key ID (use 'local' for DynamoDB Local)"
  type        = string
  default     = "local"
}

variable "dynamodb_aws_secret_access_key" {
  description = "AWS secret access key (use 'local' for DynamoDB Local)"
  type        = string
  default     = "local"
}

