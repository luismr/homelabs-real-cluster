output "namespace" {
  description = "Namespace for luismachadoreis.dev domain"
  value       = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
}

output "service_name" {
  description = "Service name for luismachadoreis.dev site"
  value       = module.luismachadoreis_dev_site.service_name
}

output "site_url" {
  description = "URL for luismachadoreis.dev site"
  value       = "https://luismachadoreis.dev"
}

output "internal_url" {
  description = "Internal Kubernetes service URL for luismachadoreis.dev"
  value       = "${module.luismachadoreis_dev_site.service_name}.${kubernetes_namespace.luismachadoreis_dev.metadata[0].name}.svc.cluster.local"
}

output "internal_url_short" {
  description = "Short internal Kubernetes service URL for luismachadoreis.dev"
  value       = "${module.luismachadoreis_dev_site.service_name}.${kubernetes_namespace.luismachadoreis_dev.metadata[0].name}"
}

# MCP Blueprint Prompts frontend service outputs
output "mcp_blueprint_prompts_frontend_service_name" {
  description = "Service name for MCP Blueprint Prompts frontend (nginx)"
  value       = module.mcp_blueprint_prompts_frontend.service_name
}

output "mcp_blueprint_prompts_frontend_deployment_name" {
  description = "Deployment name for MCP Blueprint Prompts frontend"
  value       = module.mcp_blueprint_prompts_frontend.deployment_name
}

output "mcp_blueprint_prompts_frontend_internal_url" {
  description = "Internal Kubernetes service URL for MCP Blueprint Prompts frontend"
  value       = "${module.mcp_blueprint_prompts_frontend.service_name}.${kubernetes_namespace.luismachadoreis_dev.metadata[0].name}.svc.cluster.local:80"
}

# MCP Blueprint Prompts SSE backend service outputs
output "mcp_blueprint_prompts_sse_service_name" {
  description = "Service name for MCP Blueprint Prompts SSE backend"
  value       = module.mcp_blueprint_prompts_sse.service_name
}

output "mcp_blueprint_prompts_sse_deployment_name" {
  description = "Deployment name for MCP Blueprint Prompts SSE backend"
  value       = module.mcp_blueprint_prompts_sse.deployment_name
}

output "mcp_blueprint_prompts_sse_internal_url" {
  description = "Internal Kubernetes service URL for MCP Blueprint Prompts SSE backend"
  value       = "${module.mcp_blueprint_prompts_sse.service_name}.${kubernetes_namespace.luismachadoreis_dev.metadata[0].name}.svc.cluster.local:9000"
}