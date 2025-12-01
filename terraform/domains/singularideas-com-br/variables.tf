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

variable "waha_image" {
  description = "Container image to deploy for WAHA (WhatsApp HTTP API) service"
  type        = string
  default     = null
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

variable "forms_image" {
  description = "Container image to deploy for forms service"
  type        = string
  default     = null
}

variable "forms_n8n_base_url" {
  description = "Base URL for N8N webhook endpoints (e.g., https://n8n.example.com/webhook)"
  type        = string
  default     = null
}

variable "forms_allowed_controllers" {
  description = "Comma-separated list of allowed controllers for forms service"
  type        = string
  default     = "contacts"
}

variable "forms_allowed_origins" {
  description = "Comma-separated list of allowed origins for forms service"
  type        = string
  default     = "singularideas.com.br"
}

variable "forms_origin_override" {
  description = "Origin override for forms service"
  type        = string
  default     = "singularideas.com.br"
}

