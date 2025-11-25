variable "namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "enable_nfs_storage" {
  description = "Enable NFS persistent storage for Loki"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Kubernetes StorageClass to use for persistent volumes"
  type        = string
  default     = "nfs-loki"
}

variable "loki_storage_size" {
  description = "Storage size for Loki persistent volume"
  type        = string
  default     = "50Gi"
}

variable "loki_retention_days" {
  description = "Number of days to retain logs in Loki"
  type        = number
  default     = 30
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "grafana_node_port" {
  description = "NodePort for Grafana service"
  type        = number
  default     = 30080
}

variable "prometheus_node_port" {
  description = "NodePort for Prometheus service"
  type        = number
  default     = 30090
}

variable "alertmanager_node_port" {
  description = "NodePort for Alertmanager service"
  type        = number
  default     = 30093
}

