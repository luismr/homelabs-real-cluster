variable "app_name" {
  description = "Name of the PostgreSQL application (used for resource naming)"
  type        = string
  default     = "postgres"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "domain" {
  description = "Domain name for the PostgreSQL service"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "postgres_image" {
  description = "PostgreSQL Docker image with pgvector support (should be ARM64 compatible)"
  type        = string
  default     = "pgvector/pgvector:pg17"
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
  description = "Size of persistent volume for PostgreSQL data"
  type        = string
  default     = "10Gi"
}

variable "replicas" {
  description = "Number of PostgreSQL replicas (typically 1 for single instance)"
  type        = number
  default     = 1
}

variable "resource_limits_cpu" {
  description = "CPU limit for PostgreSQL container"
  type        = string
  default     = "1000m"
}

variable "resource_limits_memory" {
  description = "Memory limit for PostgreSQL container"
  type        = string
  default     = "1Gi"
}

variable "resource_requests_cpu" {
  description = "CPU request for PostgreSQL container"
  type        = string
  default     = "200m"
}

variable "resource_requests_memory" {
  description = "Memory request for PostgreSQL container"
  type        = string
  default     = "512Mi"
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

variable "postgres_user" {
  description = "PostgreSQL superuser name"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL password for the superuser. If null, no password is set (not recommended for production)"
  type        = string
  sensitive   = true
  default     = null
}

variable "database_name" {
  description = "Name of the database to create. If null, uses 'postgres' database"
  type        = string
  default     = null
}

variable "enable_pgvector" {
  description = "Enable pgvector extension in PostgreSQL"
  type        = bool
  default     = true
}

variable "postgres_env_vars" {
  description = "Additional environment variables for PostgreSQL container"
  type        = map(string)
  default     = {}
}

variable "node_port" {
  description = "NodePort for PostgreSQL service (for external access). If null, no NodePort service is created"
  type        = number
  default     = null
}

