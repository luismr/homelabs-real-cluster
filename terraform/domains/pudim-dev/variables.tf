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

