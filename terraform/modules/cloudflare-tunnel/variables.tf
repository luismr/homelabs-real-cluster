variable "tunnel_token" {
  description = "Cloudflare Tunnel token"
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Kubernetes namespace for tunnel deployment"
  type        = string
}

variable "replicas" {
  description = "Number of cloudflared replicas"
  type        = number
  default     = 2
}

variable "image" {
  description = "Cloudflared Docker image"
  type        = string
  default     = "cloudflare/cloudflared:latest"
}

