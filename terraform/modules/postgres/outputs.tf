output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "service_port" {
  description = "The port of the PostgreSQL service"
  value       = 5432
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.postgres.metadata[0].name
}

output "pvc_name" {
  description = "The name of the PersistentVolumeClaim (if enabled)"
  value       = var.enable_nfs ? kubernetes_persistent_volume_claim.postgres_data[0].metadata[0].name : null
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the PostgreSQL service"
  value       = var.domain
}

output "database_name" {
  description = "Name of the database"
  value       = coalesce(var.database_name, "postgres")
}

output "postgres_user" {
  description = "PostgreSQL username"
  value       = var.postgres_user
}

output "config_map_name" {
  description = "The name of the ConfigMap (if pgvector is enabled)"
  value       = var.enable_pgvector ? kubernetes_config_map_v1.postgres_init[0].metadata[0].name : null
}

output "secret_name" {
  description = "The name of the password secret (if password is set)"
  value       = var.postgres_password != null ? kubernetes_secret_v1.postgres_password[0].metadata[0].name : null
}

output "nodeport_service_name" {
  description = "The name of the Kubernetes NodePort service (if enabled)"
  value       = var.node_port != null ? kubernetes_service.postgres_nodeport[0].metadata[0].name : null
}

output "node_port" {
  description = "The NodePort number for external access (if enabled)"
  value       = var.node_port
}

output "connection_string" {
  description = "PostgreSQL connection string for external access (if NodePort is enabled)"
  value       = var.node_port != null ? "postgresql://${var.postgres_user}:<password>@<MASTER_IP>:${var.node_port}/${coalesce(var.database_name, "postgres")}" : null
}

