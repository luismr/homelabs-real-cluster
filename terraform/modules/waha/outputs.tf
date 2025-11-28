output "service_name" {
  description = "The name of the Kubernetes ClusterIP service"
  value       = kubernetes_service.waha.metadata[0].name
}

output "nodeport_service_name" {
  description = "The name of the Kubernetes NodePort service"
  value       = kubernetes_service.waha_nodeport.metadata[0].name
}

output "deployment_name" {
  description = "The name of the Kubernetes deployment"
  value       = kubernetes_deployment.waha.metadata[0].name
}

output "config_map_name" {
  description = "The name of the ConfigMap"
  value       = kubernetes_config_map_v1.waha_config.metadata[0].name
}

output "node_port" {
  description = "The NodePort number for external access"
  value       = var.node_port
}

output "namespace" {
  description = "Namespace where resources are deployed"
  value       = var.namespace
}

output "domain" {
  description = "Domain name for the WAHA service"
  value       = var.domain
}

