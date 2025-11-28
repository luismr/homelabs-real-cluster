variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token for exposing services (set via CLOUDFLARE_TUNNEL_TOKEN env var or TF_VAR_cloudflare_tunnel_token)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_nfs_storage" {
  description = "Enable NFS persistent storage for sites"
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "Kubernetes StorageClass to use for persistent volumes"
  type        = string
  default     = "nfs-client"
}

variable "pudim_site_image" {
  description = "Image for pudim.dev site"
  type        = string
  default     = null
}

variable "luismachadoreis_site_image" {
  description = "Image for luismachadoreis.dev site"
  type        = string
  default     = null
}

variable "carimbo_site_image" {
  description = "Image for carimbo.vip site"
  type        = string
  default     = null
}

variable "carimbo_forms_image" {
  description = "Image for carimbo.vip forms service"
  type        = string
  default     = null
}

variable "carimbo_waha_image" {
  description = "Image for carimbo.vip WAHA (WhatsApp HTTP API) service"
  type        = string
  default     = null
}

variable "carimbo_waha_api_key" {
  description = "WAHA API key for carimbo.vip WAHA service"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_waha_dashboard_username" {
  description = "WAHA dashboard username for carimbo.vip"
  type        = string
  default     = "admin"
}

variable "carimbo_waha_dashboard_password" {
  description = "WAHA dashboard password for carimbo.vip"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_waha_swagger_username" {
  description = "WAHA Swagger/API docs username for carimbo.vip"
  type        = string
  default     = "admin"
}

variable "carimbo_waha_swagger_password" {
  description = "WAHA Swagger/API docs password for carimbo.vip"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_n8n_image" {
  description = "Image for carimbo.vip n8n service"
  type        = string
  default     = null
}

variable "carimbo_n8n_timezone" {
  description = "Timezone for carimbo.vip n8n service (e.g., America/Sao_Paulo)"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "singularideas_site_image" {
  description = "Image for singularideas.com.br site"
  type        = string
  default     = null
}

variable "ligflat_site_image" {
  description = "Image for ligflat.com.br site"
  type        = string
  default     = null
}

variable "leticiacarvalho_pro_site_image" {
  description = "Image for leticiacarvalho.pro site"
  type        = string
  default     = null
}

variable "ghcr_username" {
  description = "GitHub username (or org) for GHCR auth (set via GITHUB_USER env var or TF_VAR_ghcr_username)"
  type        = string
  default     = null
}

variable "ghcr_token" {
  description = "GitHub token with read:packages for GHCR (set via GITHUB_TOKEN env var or TF_VAR_ghcr_token)"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_redis_image" {
  description = "Image for carimbo.vip Redis service (should be ARM64 compatible)"
  type        = string
  default     = "redis:7-alpine"
}

variable "carimbo_postgres_image" {
  description = "Image for carimbo.vip PostgreSQL service with pgvector (should be ARM64 compatible)"
  type        = string
  default     = "pgvector/pgvector:pg17"
}

variable "carimbo_postgres_password" {
  description = "PostgreSQL password for carimbo.vip (set via POSTGRES_PASSWORD env var or TF_VAR_carimbo_postgres_password)"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_postgres_database_name" {
  description = "PostgreSQL database name for carimbo.vip"
  type        = string
  default     = "carimbo"
}

variable "carimbo_postgres_node_port" {
  description = "NodePort for carimbo.vip PostgreSQL service (for external access like Grafana). Set to null to disable NodePort"
  type        = number
  default     = 30432 # PostgreSQL default port 5432 + 25000
}


