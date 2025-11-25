variable "app_name" {
  description = "Name of the application (used for resource naming)"
  type        = string
}

variable "domain" {
  description = "Domain name for the site"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "development"
}

variable "replicas" {
  description = "Number of app replicas"
  type        = number
  default     = 2
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

variable "app_image" {
  description = "Application Docker image"
  type        = string
}

variable "image_pull_secret_name" {
  description = "Kubernetes imagePullSecret name used to pull private images"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "service_port" {
  description = "Port the service listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for the health check endpoint"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Port for the health check endpoint. Defaults to container_port if not set."
  type        = number
  default     = null
}

variable "health_check_initial_delay" {
  description = "Initial delay for the liveness probe"
  type        = number
  default     = 10
}

variable "health_check_period" {
  description = "Period for the liveness probe"
  type        = number
  default     = 10
}

variable "resource_limits_cpu" {
  description = "CPU limit for app container"
  type        = string
  default     = "200m"
}

variable "resource_limits_memory" {
  description = "Memory limit for app container"
  type        = string
  default     = "256Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for app container"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory resource requests"
  type        = string
  default     = "128Mi"
}

variable "enable_autoscaling" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = false
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

variable "cpu_target_percentage" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 80
}

variable "memory_target_percentage" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 80
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

variable "config_map_name" {
  description = "Name of ConfigMap to use for environment variables"
  type        = string
  default     = null
}
