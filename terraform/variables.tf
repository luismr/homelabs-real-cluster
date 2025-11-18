variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token for exposing services"
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

