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

variable "pudim_redis_enabled" {
  description = "Enable Redis caching for pudim.dev calculator"
  type        = bool
  default     = true
}

variable "pudim_redis_prefix" {
  description = "Redis key prefix for pudim.dev calculator cache"
  type        = string
  default     = "pudim:"
}

variable "pudim_redis_ttl" {
  description = "Redis TTL (seconds) for pudim.dev calculator cache"
  type        = number
  default     = 3600
}

variable "pudim_redis_circuit_breaker_cooldown_ms" {
  description = "Redis circuit breaker cooldown (ms) for pudim.dev calculator"
  type        = number
  default     = 60000
}

variable "pudim_redis_maxmemory" {
  description = "Redis maxmemory value (e.g., '128mb') for pudim.dev calculator cache. Set null to omit."
  type        = string
  default     = "128mb"
}

variable "pudim_redis_maxmemory_policy" {
  description = "Redis maxmemory eviction policy for pudim.dev calculator cache"
  type        = string
  default     = "allkeys-lru"
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

variable "carimbo_forms_n8n_base_url" {
  description = "Base URL for N8N webhook endpoints for carimbo.vip forms service (e.g., https://n8n.example.com/webhook)"
  type        = string
  default     = null
}

variable "carimbo_forms_allowed_controllers" {
  description = "Comma-separated list of allowed controllers for carimbo.vip forms service"
  type        = string
  default     = "leads,contacts"
}

variable "carimbo_forms_allowed_origins" {
  description = "Comma-separated list of allowed origins for carimbo.vip forms service"
  type        = string
  default     = "carimbo.vip"
}

variable "carimbo_forms_origin_override" {
  description = "Origin override for carimbo.vip forms service"
  type        = string
  default     = "carimbo.vip"
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

variable "singularideas_forms_image" {
  description = "Image for singularideas.com.br forms service"
  type        = string
  default     = null
}

variable "singularideas_forms_n8n_base_url" {
  description = "Base URL for N8N webhook endpoints for singularideas.com.br forms service (e.g., https://n8n.example.com/webhook)"
  type        = string
  default     = null
}

variable "singularideas_forms_allowed_controllers" {
  description = "Comma-separated list of allowed controllers for singularideas.com.br forms service"
  type        = string
  default     = "contacts"
}

variable "singularideas_forms_allowed_origins" {
  description = "Comma-separated list of allowed origins for singularideas.com.br forms service"
  type        = string
  default     = "singularideas.com.br"
}

variable "singularideas_forms_origin_override" {
  description = "Origin override for singularideas.com.br forms service"
  type        = string
  default     = "singularideas.com.br"
}

variable "singularideas_waha_image" {
  description = "Image for singularideas.com.br WAHA (WhatsApp HTTP API) service"
  type        = string
  default     = null
}

variable "singularideas_waha_api_key" {
  description = "WAHA API key for singularideas.com.br WAHA service"
  type        = string
  sensitive   = true
  default     = null
}

variable "singularideas_waha_dashboard_username" {
  description = "WAHA dashboard username for singularideas.com.br"
  type        = string
  default     = "admin"
}

variable "singularideas_waha_dashboard_password" {
  description = "WAHA dashboard password for singularideas.com.br"
  type        = string
  sensitive   = true
  default     = null
}

variable "singularideas_waha_swagger_username" {
  description = "WAHA Swagger/API docs username for singularideas.com.br"
  type        = string
  default     = "admin"
}

variable "singularideas_waha_swagger_password" {
  description = "WAHA Swagger/API docs password for singularideas.com.br"
  type        = string
  sensitive   = true
  default     = null
}

variable "carimbo_waha_restart_all_sessions" {
  description = "Enable restart all WhatsApp sessions on startup for carimbo.vip WAHA"
  type        = bool
  default     = false
}

variable "carimbo_waha_start_session" {
  description = "WhatsApp session to start automatically for carimbo.vip WAHA (e.g., 'default')"
  type        = string
  default     = null
}

variable "singularideas_waha_restart_all_sessions" {
  description = "Enable restart all WhatsApp sessions on startup for singularideas.com.br WAHA"
  type        = bool
  default     = false
}

variable "singularideas_waha_start_session" {
  description = "WhatsApp session to start automatically for singularideas.com.br WAHA (e.g., 'default')"
  type        = string
  default     = null
}

variable "carimbo_waha_hook_url" {
  description = "Webhook URL for carimbo.vip WAHA to send events"
  type        = string
  default     = null
}

variable "singularideas_waha_hook_url" {
  description = "Webhook URL for singularideas.com.br WAHA to send events"
  type        = string
  default     = null
}

variable "carimbo_waha_hook_events" {
  description = "Comma-separated list of events to send to webhook for carimbo.vip WAHA (default: 'message,message.any,state.change')"
  type        = string
  default     = "message,message.any,state.change"
}

variable "singularideas_waha_hook_events" {
  description = "Comma-separated list of events to send to webhook for singularideas.com.br WAHA (default: 'message,message.any,state.change')"
  type        = string
  default     = "message,message.any,state.change"
}


