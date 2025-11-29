variable "app_name" {
  description = "Name of the n8n application (used for resource naming)"
  type        = string
  default     = "n8n"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "domain" {
  description = "Domain name for the n8n service"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "n8n_image" {
  description = "n8n Docker image"
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
  description = "Size of persistent volume for n8n data"
  type        = string
  default     = "5Gi"
}

variable "n8n_timezone" {
  description = "Timezone for n8n service (e.g., America/Sao_Paulo)"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "replicas" {
  description = "Number of n8n replicas"
  type        = number
  default     = 1
}

variable "resource_limits_cpu" {
  description = "CPU limit for n8n container"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for n8n container"
  type        = string
  default     = "512Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for n8n container"
  type        = string
  default     = "200m"
}

variable "resource_requests_memory" {
  description = "Memory request for n8n container"
  type        = string
  default     = "256Mi"
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

variable "enable_cloudflare_tunnel" {
  description = "Enable Cloudflare Tunnel annotation on the service"
  type        = bool
  default     = false
}

variable "webhook_url" {
  description = "Webhook URL for n8n (e.g., engine.carimbo.vip)"
  type        = string
  default     = null
}

variable "n8n_host" {
  description = "Hostname for n8n (e.g., engine.carimbo.vip)"
  type        = string
  default     = null
}

variable "n8n_protocol" {
  description = "Protocol for n8n (http or https)"
  type        = string
  default     = null
}

variable "n8n_proxy_hops" {
  description = "Number of proxy hops if behind a reverse proxy"
  type        = number
  default     = null
}
