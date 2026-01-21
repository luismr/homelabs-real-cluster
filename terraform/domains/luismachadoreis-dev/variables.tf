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
variable "site_image" {
  description = "Container image to deploy for this site"
  type        = string
  default     = null
}


variable "mcp_blueprint_prompts_site_image" {
  description = "Container image for MCP Blueprint Prompts frontend (site)"
  type        = string
  default     = "luismachadoreis/the-pudim-blueprint-prompts:site-1.6.1"
}

variable "mcp_blueprint_prompts_sse_image" {
  description = "Container image for MCP Blueprint Prompts SSE backend"
  type        = string
  default     = "luismachadoreis/the-pudim-blueprint-prompts:1.6.1"
}
