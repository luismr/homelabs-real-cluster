variable "app_name" {
  description = "Name of the forms application (used for resource naming)"
  type        = string
  default     = "forms"
}

variable "domain" {
  description = "Domain name for the forms service (e.g., forms.carimbo.vip)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "forms_image" {
  description = "Container image to deploy for forms service"
  type        = string
}

variable "image_pull_secret_name" {
  description = "Kubernetes imagePullSecret name used to pull private images"
  type        = string
  default     = null
}

variable "enable_nfs" {
  description = "Enable NFS persistent storage"
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "StorageClass to use for persistent volume"
  type        = string
  default     = "nfs-client"
}

variable "storage_size" {
  description = "Size of persistent volume"
  type        = string
  default     = "1Gi"
}

variable "enable_autoscaling" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
  default     = 3
}

variable "resource_limits_cpu" {
  description = "CPU limit for forms container"
  type        = string
  default     = "200m"
}

variable "resource_limits_memory" {
  description = "Memory limit for forms container"
  type        = string
  default     = "256Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for forms container"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory request for forms container"
  type        = string
  default     = "128Mi"
}

# Forms-specific environment variables
variable "turnstile_secret_key" {
  description = "Turnstile secret key for forms service"
  type        = string
  default     = null
}

variable "turnstile_enabled" {
  description = "Enable Turnstile for forms service"
  type        = string
  default     = "true"
}

variable "cors_origin" {
  description = "CORS origin for forms service"
  type        = string
  default     = null
}

variable "n8n_base_url" {
  description = "Base URL for N8N webhook endpoints (e.g., https://n8n.example.com/webhook)"
  type        = string
  default     = null
}

variable "allowed_controllers" {
  description = "Comma-separated list of allowed controllers for forms service"
  type        = string
  default     = "leads,contacts"
}

variable "allowed_origins" {
  description = "Comma-separated list of allowed origins for forms service"
  type        = string
  default     = "carimbo.vip"
}

variable "origin_override" {
  description = "Origin override for forms service"
  type        = string
  default     = "carimbo.vip"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "service_port" {
  description = "Port the service listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for the health check endpoint"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Port for the health check endpoint"
  type        = number
  default     = 3000
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

