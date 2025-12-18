output "service_name" {
  description = "The name of the Kubernetes service"
  value       = kubernetes_service.dynamodb_local.metadata[0].name
}

output "service_port" {
  description = "The port of the DynamoDB Local service"
  value       = 8000
}

output "service_url" {
  description = "The full service URL for DynamoDB Local (for in-cluster access)"
  value       = "http://${kubernetes_service.dynamodb_local.metadata[0].name}.${var.namespace}.svc.cluster.local:8000"
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.dynamodb_local.metadata[0].name
}

output "pvc_name" {
  description = "The name of the PersistentVolumeClaim (if enabled)"
  value       = var.enable_nfs ? kubernetes_persistent_volume_claim.dynamodb_data[0].metadata[0].name : null
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the DynamoDB Local service"
  value       = var.domain
}

