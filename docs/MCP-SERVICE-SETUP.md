# MCP Blueprint Prompts Service Setup

This guide explains how the MCP (Model Context Protocol) Blueprint Prompts service is deployed and exposed via Cloudflare Tunnel.

## Overview

The MCP Blueprint Prompts service provides a Server-Sent Events (SSE) endpoint for MCP protocol communication. It's deployed in the `luismachadoreis-dev` namespace and accessible via subdomain routing.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Internet                              │
│                       ↓                                  │
│    ┌──────────────────────────────────────────┐         │
│    │ Cloudflare Network (Global CDN)          │         │
│    │  prompts.luismachadoreis.dev (DNS)       │         │
│    └──────────────┬───────────────────────────┘         │
│                   │                                      │
│    ┌──────────────▼───────────────────────────┐         │
│    │  Cloudflare Tunnel (Encrypted)           │         │
│    │  Hostname: prompts.luismachadoreis.dev   │         │
│    └──────────────┬───────────────────────────┘         │
└───────────────────┼──────────────────────────────────────┘
                    │ HTTPS/QUIC
                    ▼
┌──────────────────────────────────────────────────────────┐
│         Kubernetes Cluster (k3s)                         │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Namespace: luismachadoreis-dev                     │ │
│  │                                                    │ │
│  │  ┌────────────────────────────────────┐           │ │
│  │  │ Service: mcp-blueprint-prompts     │           │ │
│  │  │ Type: ClusterIP                    │           │ │
│  │  │ Port: 9000                         │           │ │
│  │  └──────────┬─────────────────────────┘           │ │
│  │             │                                     │ │
│  │  ┌──────────▼─────────────────────────┐           │ │
│  │  │ Deployment: mcp-blueprint-prompts  │           │ │
│  │  │ Replicas: 1                        │           │ │
│  │  │ Container Port: 9000               │           │ │
│  │  │ Image: luismachadoreis/the-pudim-  │           │ │
│  │  │        blueprint-prompts:latest    │           │ │
│  │  └────────────────────────────────────┘           │ │
│  │                                                    │ │
│  │  ┌────────────────────────────────────┐           │ │
│  │  │ Service: mcp-blueprint-prompts-    │           │ │
│  │  │          nodeport                  │           │ │
│  │  │ Type: NodePort                     │           │ │
│  │  │ NodePort: 30091                    │           │ │
│  │  │ (Local access: 192.168.7.200:30091)│           │ │
│  │  └────────────────────────────────────┘           │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Deployment Configuration

The service is deployed using the `app-service` Terraform module:

```hcl
module "mcp_blueprint_prompts" {
  source = "../../modules/app-service"

  app_name           = "mcp-blueprint-prompts"
  domain             = "luismachadoreis.dev"
  namespace          = kubernetes_namespace.luismachadoreis_dev.metadata[0].name
  environment        = "production"
  replicas           = 1
  enable_autoscaling = false
  enable_nfs         = false

  app_image              = "luismachadoreis/the-pudim-blueprint-prompts:latest"
  container_port         = 9000
  service_port           = 9000
  health_check_path      = "/"
  health_check_port      = 9000

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  # NodePort for local access
  node_port = 30091

  depends_on_resources = [kubernetes_namespace.luismachadoreis_dev]
}
```

## Cloudflare Tunnel Configuration

The service is exposed via subdomain routing in the Cloudflare Tunnel:

```yaml
# In modules/cloudflare-tunnel/main.tf
ingress:
  # ... other routes ...
  
  - hostname: prompts.luismachadoreis.dev
    service: http://mcp-blueprint-prompts.luismachadoreis-dev.svc.cluster.local:9000
  
  # ... other routes ...
```

### Why Subdomain Routing?

Cloudflare Tunnel only supports **hostname-based routing**, not path-based routing. This means:
- ✅ You CAN route `prompts.luismachadoreis.dev` to the MCP service
- ❌ You CANNOT route `luismachadoreis.dev/prompts/mcp/` to the MCP service

Benefits of subdomain routing:
- Direct connection to the service (no reverse proxy layers)
- Better SSE streaming performance
- Cleaner separation of concerns
- Easier to manage in DNS

## DNS Configuration

Add a CNAME record in Cloudflare:

```
Type: CNAME
Name: prompts
Content: <your-tunnel-uuid>.cfargotunnel.com
Proxy: Yes (Orange cloud)
TTL: Auto
```

## Endpoints

### Public Endpoint (via Cloudflare)
```
https://prompts.luismachadoreis.dev/sse
```

### Local Endpoint (NodePort)
```
http://192.168.7.200:30091/sse
```

### Cluster Internal Endpoint
```
http://mcp-blueprint-prompts.luismachadoreis-dev.svc.cluster.local:9000/sse
```

## SSE (Server-Sent Events) Support

The service uses SSE for real-time communication. Cloudflare Tunnel handles SSE connections properly:

- **No buffering**: Cloudflare passes through SSE streams without buffering
- **Long-lived connections**: Connections stay open for streaming
- **Proper headers**: `Content-Type: text/event-stream` is preserved

## Testing

### Test Public Endpoint
```bash
# Check headers
curl -I https://prompts.luismachadoreis.dev/sse

# Test SSE connection (will stay open)
curl -N https://prompts.luismachadoreis.dev/sse
```

### Test Local NodePort
```bash
# Check headers
curl -I http://192.168.7.200:30091/sse

# Test SSE connection
curl -N http://192.168.7.200:30091/sse
```

### Test from within cluster
```bash
kubectl run -it --rm test-mcp --image=curlimages/curl --restart=Never -- \
  curl -I http://mcp-blueprint-prompts.luismachadoreis-dev.svc.cluster.local:9000/sse
```

## Monitoring

### Check Pod Status
```bash
kubectl get pods -n luismachadoreis-dev -l app=mcp-blueprint-prompts
```

### View Logs
```bash
kubectl logs -n luismachadoreis-dev -l app=mcp-blueprint-prompts --tail=100 -f
```

### Check Service
```bash
kubectl get svc -n luismachadoreis-dev mcp-blueprint-prompts
kubectl get svc -n luismachadoreis-dev mcp-blueprint-prompts-nodeport
```

### Test Health Check
```bash
curl http://192.168.7.200:30091/
```

## Troubleshooting

### Service not accessible via public URL

1. **Check DNS**:
   ```bash
   dig prompts.luismachadoreis.dev
   nslookup prompts.luismachadoreis.dev
   ```

2. **Check Cloudflare Tunnel logs**:
   ```bash
   kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel --tail=50
   ```
   Look for: `hostname: prompts.luismachadoreis.dev`

3. **Verify tunnel configuration**:
   ```bash
   kubectl get configmap -n cloudflare-tunnel cloudflare-tunnel-config -o yaml | grep prompts
   ```

4. **Restart tunnel pods**:
   ```bash
   kubectl rollout restart deployment/cloudflare-tunnel -n cloudflare-tunnel
   kubectl rollout status deployment/cloudflare-tunnel -n cloudflare-tunnel
   ```

### NodePort not accessible

1. **Check service**:
   ```bash
   kubectl get svc -n luismachadoreis-dev mcp-blueprint-prompts-nodeport
   ```

2. **Verify pod is running**:
   ```bash
   kubectl get pods -n luismachadoreis-dev -l app=mcp-blueprint-prompts
   ```

3. **Test from master node**:
   ```bash
   ssh ubuntu@192.168.7.200
   curl http://localhost:30091/sse
   ```

### SSE connection issues

1. **Check for buffering**:
   ```bash
   curl -I https://prompts.luismachadoreis.dev/sse
   # Look for: Content-Type: text/event-stream
   # Look for: Cache-Control: no-store
   ```

2. **Test SSE stream**:
   ```bash
   # Should keep connection open
   curl -N --max-time 5 https://prompts.luismachadoreis.dev/sse
   ```

3. **Check application logs**:
   ```bash
   kubectl logs -n luismachadoreis-dev -l app=mcp-blueprint-prompts -f
   ```

## Updating the Service

### Update Image
```bash
cd terraform
# Edit terraform.tfvars or domains/luismachadoreis-dev/main.tf
# Change: app_image = "luismachadoreis/the-pudim-blueprint-prompts:new-version"
terraform apply
```

### Scale Replicas
```bash
# Edit domains/luismachadoreis-dev/main.tf
# Change: replicas = 2
terraform apply
```

### Enable Autoscaling
```hcl
module "mcp_blueprint_prompts" {
  # ... other config ...
  
  enable_autoscaling = true
  min_replicas       = 1
  max_replicas       = 3
  
  cpu_target_percentage    = 80
  memory_target_percentage = 80
}
```

## Security Considerations

1. **No authentication**: Current setup has no authentication on the SSE endpoint
2. **Public access**: The service is publicly accessible via Cloudflare
3. **Rate limiting**: Consider adding Cloudflare rate limiting rules
4. **Network policies**: Consider adding Kubernetes NetworkPolicies

## Related Documentation

- [Terraform README](../terraform/README.md) - Main Terraform documentation
- [Cloudflare Tunnel Setup](./CLOUDFLARE-TUNNEL-SETUP.md) - Tunnel configuration guide
- [Domains README](../terraform/domains/README.md) - Domain module documentation
