variable "app_name" {
  description = "Name of the DynamoDB Local application (used for resource naming)"
  type        = string
  default     = "dynamodb-local"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "domain" {
  description = "Domain name for the DynamoDB Local service"
  type        = string
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "dynamodb_image" {
  description = "DynamoDB Local Docker image (should be ARM64 compatible)"
  type        = string
  default     = "amazon/dynamodb-local:latest"
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
  description = "Size of persistent volume for DynamoDB Local data"
  type        = string
  default     = "1Gi"
}

variable "replicas" {
  description = "Number of DynamoDB Local replicas (typically 1 for single instance)"
  type        = number
  default     = 1
}

variable "resource_limits_cpu" {
  description = "CPU limit for DynamoDB Local container"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for DynamoDB Local container"
  type        = string
  default     = "512Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for DynamoDB Local container"
  type        = string
  default     = "100m"
}

variable "resource_requests_memory" {
  description = "Memory request for DynamoDB Local container"
  type        = string
  default     = "256Mi"
}

variable "depends_on_resources" {
  description = "List of resources to depend on"
  type        = list(any)
  default     = []
}

