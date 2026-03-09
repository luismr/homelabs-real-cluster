variable "environment" {
  description = "Environment name (e.g. qa, prod)"
  type        = string
}

variable "namespace_name" {
  description = "Kubernetes namespace name (e.g. brickfolio-online-qa)"
  type        = string
}

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

variable "api_image" {
  description = "Container image for brickfolio-api"
  type        = string
}

variable "app_image" {
  description = "Container image for brickfolio-app"
  type        = string
}

variable "api_replicas" {
  description = "Number of API replicas"
  type        = number
  default     = 1
}

variable "app_replicas" {
  description = "Number of App replicas"
  type        = number
  default     = 1
}

variable "postgres_password" {
  description = "PostgreSQL password for user brickfolio"
  type        = string
  sensitive   = true
}

variable "api_public_host" {
  description = "Public hostname for the API (e.g. api.brickfolio.online or api.brickfolio-qa.online)"
  type        = string
}

variable "app_public_host" {
  description = "Public hostname for the app (e.g. app.brickfolio.online or app.brickfolio-qa.online)"
  type        = string
}

variable "api_cors_allowed_origins" {
  description = "CORS allowed origin for the API (e.g. https://app.brickfolio.online)"
  type        = string
  default     = ""
}

variable "api_jwt_secret" {
  description = "JWT secret for the API (optional; if null, API uses default from application.yaml). Must be at least 32 characters (256 bits) for HS256."
  type        = string
  sensitive   = true
  default     = null
}
