variable "app_name" {
  description = "Name of the WAHA application (used for resource naming)"
  type        = string
  default     = "waha"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "domain" {
  description = "Domain name for the WAHA service"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "waha_image" {
  description = "WAHA Docker image"
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
  default     = true
}

variable "storage_class" {
  description = "StorageClass to use for persistent volume"
  type        = string
  default     = "nfs-client"
}

variable "storage_size" {
  description = "Size of persistent volume for WAHA session data"
  type        = string
  default     = "5Gi"
}

variable "waha_api_key" {
  description = "WAHA API key for authentication"
  type        = string
  sensitive   = true
  default     = null
}

variable "waha_dashboard_username" {
  description = "WAHA dashboard username"
  type        = string
  default     = "admin"
}

variable "waha_dashboard_password" {
  description = "WAHA dashboard password"
  type        = string
  sensitive   = true
  default     = null
}

variable "waha_swagger_username" {
  description = "WAHA Swagger/API docs username"
  type        = string
  default     = "admin"
}

variable "waha_swagger_password" {
  description = "WAHA Swagger/API docs password"
  type        = string
  sensitive   = true
  default     = null
}

variable "node_port" {
  description = "NodePort for WAHA service (for external access)"
  type        = number
  default     = 30100
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
  description = "CPU limit for WAHA container"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for WAHA container"
  type        = string
  default     = "512Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for WAHA container"
  type        = string
  default     = "200m"
}

variable "resource_requests_memory" {
  description = "Memory request for WAHA container"
  type        = string
  default     = "256Mi"
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

