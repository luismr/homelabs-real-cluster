variable "app_name" {
  description = "Name of the Redis application (used for resource naming)"
  type        = string
  default     = "redis"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "domain" {
  description = "Domain name for the Redis service"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "redis_image" {
  description = "Redis Docker image (should be ARM64 compatible)"
  type        = string
  default     = "redis:7-alpine"
}

variable "image_pull_secret_name" {
  description = "Kubernetes imagePullSecret name used to pull private images"
  type        = string
  default     = null
}

variable "enable_nfs" {
  description = "Enable NFS persistent storage"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "StorageClass to use for persistent volume"
  type        = string
  default     = "nfs-client"
}

variable "storage_size" {
  description = "Size of persistent volume for Redis data"
  type        = string
  default     = "2Gi"
}

variable "replicas" {
  description = "Number of Redis replicas (typically 1 for single instance)"
  type        = number
  default     = 1
}

variable "resource_limits_cpu" {
  description = "CPU limit for Redis container"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for Redis container"
  type        = string
  default     = "512Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for Redis container"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory request for Redis container"
  type        = string
  default     = "256Mi"
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

variable "maxmemory_policy" {
  description = "Redis maxmemory eviction policy"
  type        = string
  default     = "allkeys-lru"
}

variable "maxmemory" {
  description = "Maximum memory Redis can use (e.g., '256mb'). If null, uses container memory limit"
  type        = string
  default     = null
}

variable "requirepass" {
  description = "Redis password (AUTH). If null, no password is set"
  type        = string
  default     = null
}

variable "protected_mode" {
  description = "Enable Redis protected mode"
  type        = bool
  default     = true
}

