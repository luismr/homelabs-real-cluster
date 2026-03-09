# Terraform Infrastructure for Kubernetes

This directory contains Terraform configurations to manage Kubernetes deployments for static websites with Cloudflare Tunnel integration.

## Overview

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare Network                        │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐         │
│  │ pudim.dev  │   │luismachado │   │carimbo.vip │         │
│  │            │   │  reis.dev  │   │            │         │
│  └──────┬─────┘   └──────┬─────┘   └──────┬─────┘         │
│         │                │                │                 │
│         └────────────────┼────────────────┘                 │
│                          │                                  │
│                  Cloudflare Tunnel                          │
└──────────────────────────┼──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                  Kubernetes Cluster                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Namespace: pudim-dev             (Production)        │  │
│  │  ┌─────────────┐   ┌──────────┐                    │  │
│  │  │ Deployment  │──▶│ Service  │                    │  │
│  │  │ (nginx x3)  │   │ClusterIP │                    │  │
│  │  └─────────────┘   │static-site                    │  │
│  └─────────────────────────┴──────────────────────────┘  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Namespace: luismachadoreis-dev   (Production)        │  │
│  │  ┌─────────────┐   ┌──────────┐   ┌────────────┐   │  │
│  │  │ Deployment  │──▶│ Service  │   │ PVC (NFS)  │   │  │
│  │  │ (nginx x3)  │   │ClusterIP │   │    1Gi     │   │  │
│  │  └─────────────┘   │static-site   └────────────┘   │  │
│  └─────────────────────────┴──────────────────────────┘  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Namespace: carimbo-vip           (Production)        │  │
│  │  ┌─────────────┐   ┌──────────┐   ┌────────────┐   │  │
│  │  │ Deployment  │──▶│ Service  │   │ PVC (NFS)  │   │  │
│  │  │ (nginx x3)  │   │ClusterIP │   │    1Gi     │   │  │
│  │  └─────────────┘   │static-site   └────────────┘   │  │
│  └─────────────────────────┴──────────────────────────┘  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Namespace: cloudflare-tunnel     (Shared)            │  │
│  │  ┌─────────────────────────────────────────────────┐ │  │
│  │  │ Cloudflare Tunnel (cloudflared x2)              │ │  │
│  │  │ Token-based auth, routes to all domains         │ │  │
│  │  └─────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
terraform/
├── README.md                          ← You are here
├── versions.tf                        ← Terraform & provider versions
├── providers.tf                       ← Kubernetes & Helm provider config
├── variables.tf                       ← Input variables
├── main.tf                            ← Main orchestrator
├── outputs.tf                         ← Output values
├── terraform.tfvars.example           ← Example variables file
├── terraform.tfvars                   ← Your variables (gitignored)
├── domains/                           ← Domain-specific modules
│   ├── README.md                      ← Domain module documentation
│   ├── pudim-dev/                     ← pudim.dev configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── luismachadoreis-dev/           ← luismachadoreis.dev config
│   │   ├── main.tf                      (static site + MCP service)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── carimbo-vip/                   ← carimbo.vip configuration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── brickfolio-environment/        ← Reusable QA/PROD environment module
│       ├── main.tf                      (namespace, Redis, Postgres, API, App)
│       ├── variables.tf
│       └── outputs.tf
└── modules/                           ← Reusable modules
    ├── nginx-static-site/             ← Static site module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── app-service/                   ← Generic application service module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloudflare-tunnel/             ← Shared tunnel module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── nginx-redirector/              ← Redirects module (301 to canonical domains)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

1. **Terraform** >= 1.0
   ```bash
   brew install terraform
   ```

2. **kubectl** configured with cluster access
   ```bash
   export KUBECONFIG=~/.kube/config-homelabs
   kubectl get nodes
   ```

3. **Cloudflare Tunnel Token**
   - Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
   - Navigate to: Networks > Tunnels
   - Create a new tunnel or use existing
   - Copy the tunnel token

4. **NFS Storage** (optional)
   ```bash
   ./scripts/setup-nfs-complete.sh
   ```

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` (example):
```hcl
cloudflare_tunnel_token = "your-actual-token-here"
enable_nfs_storage      = false
storage_class           = "nfs-client"

# Per-site images (built by your CI)
pudim_site_image             = "ghcr.io/ORG/pudim:latest"
luismachadoreis_site_image   = "ghcr.io/ORG/luis:latest"
carimbo_site_image           = "ghcr.io/ORG/carimbo:latest"

# Private GHCR auth (token needs read:packages)
ghcr_username = "your-gh-username-or-org"
ghcr_token    = "ghp_xxx"
```

### 3. Plan Changes

```bash
terraform plan
```

Review the planned changes. You should see:
- 4 namespaces (pudim-dev, luismachadoreis-dev, carimbo-vip, cloudflare-tunnel)
- 3 deployments (one per site, 3 replicas each)
- 3 services (ClusterIP, all named "static-site")
- 1 Cloudflare Tunnel deployment (2 replicas, shared)

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` to confirm.

### 5. Verify Deployment

```bash
# Check all site pods
kubectl get pods -A | grep -E "(pudim|luis|carimbo)"

# Check tunnel pods
kubectl get pods -n cloudflare-tunnel

# Check services
kubectl get svc -A | grep static-site

# (Optional) Check PVCs if you enabled NFS later
kubectl get pvc -A || true

# Test locally (port-forward)
kubectl port-forward -n pudim-dev svc/static-site 8080:80
# Open http://localhost:8080
```

## Deployed Services

After deployment, these services will be available:

### Static Sites

| Site | Domain | Namespace | Service Name | Replicas | Environment |
|------|--------|-----------|--------------|----------|-------------|
| Pudim | pudim.dev | pudim-dev | static-site | Autoscaled 1-3 | Production |
| Luis Machado Reis | luismachadoreis.dev | luismachadoreis-dev | static-site | Autoscaled 1-3 | Production |
| Carimbo | carimbo.vip | carimbo-vip | static-site | Autoscaled 1-3 | Production |

### Application Services

| Application | Domain | Namespace | Service Name | Port | Type |
|-------------|--------|-----------|--------------|------|------|
| MCP Blueprint Prompts | prompts.luismachadoreis.dev | luismachadoreis-dev | mcp-blueprint-prompts | 9000 | SSE/HTTP |

### Brickfolio App Environments

Two dedicated environments (QA and PROD) each run in an isolated namespace and share the same module (`domains/brickfolio-environment`). Each includes: Redis, Postgres 17, Spring Boot API, and a Vite SPA frontend.

| Environment | App URL | API URL | Namespace |
|-------------|---------|---------|-----------|
| **PROD** | app.brickfolio.online | api.brickfolio.online | `brickfolio-online-prod` |
| **QA** | app.brickfolio-qa.online | api.brickfolio-qa.online | `brickfolio-online-qa` |

**Per-environment components:**

| Component | Service name | Port | Notes |
|-----------|-------------|------|-------|
| API (Spring Boot) | `api` | 8080 | 2 replicas PROD / 1 QA |
| App (Vite SPA) | `app` | 80 | 2 replicas PROD / 1 QA |
| Postgres 17 | `postgres` | 5432 | DB: `brickfolio_db`, user: `brickfolio` |
| Redis 7 | `redis` | 6379 | No auth, standalone |

**Environment variables (API):**

| Variable | Value |
|----------|-------|
| `DATABASE_URL` | `jdbc:postgresql://postgres:5432/brickfolio_db` |
| `DATABASE_USERNAME` | `brickfolio` |
| `DATABASE_PASSWORD` | From `api-secrets` Secret |
| `REDIS_HOST` | `redis` (in-namespace service name) |
| `REDIS_PORT` | `6379` |
| `JWT_SECRET` | From `api-secrets` Secret (≥ 32 chars required for HS256) |
| `APP_CORS_ALLOWED_ORIGINS_0` | App public URL for this environment |

**Environment variables (App / runtime config):**

The app uses a `runtime-config.js` file generated at container start from env vars injected via the `app-config` ConfigMap. Values are available as `window.__RUNTIME_CONFIG__.<KEY>`.

| Variable | PROD value | QA value |
|----------|------------|----------|
| `VITE_API_URL` | `https://api.brickfolio.online` | `https://api.brickfolio-qa.online` |
| `VITE_AUTH_MODE` | `api` | `api` |
| `VITE_API_TIMEOUT` | `10000` | `10000` |

> **Note:** VITE_* are injected at runtime via the ConfigMap, not baked at build time. After a ConfigMap change, restart the app deployment (`kubectl rollout restart deployment/app -n <namespace>`) and **purge the Cloudflare cache** for `runtime-config.js` to avoid serving a stale cached version to browsers.

**Required secrets (set via env vars or tfvars, never commit):**

```bash
export TF_VAR_brickfolio_prod_postgres_password="<min 16 chars>"
export TF_VAR_brickfolio_prod_api_jwt_secret="<min 32 chars>"
export TF_VAR_brickfolio_qa_postgres_password="<min 16 chars>"
export TF_VAR_brickfolio_qa_api_jwt_secret="<min 32 chars>"
```

**Architecture Notes:**
- Each domain has its own isolated namespace
- Static sites use the standardized name `static-site` within their namespace
- Application services have unique names (e.g., `mcp-blueprint-prompts`)
- Cloudflare Tunnel runs in a separate `cloudflare-tunnel` namespace (2 replicas)
- Full DNS name format: `http://<service-name>.<namespace>.svc.cluster.local:<port>`

**Routing:**
- Cloudflare Tunnel uses **hostname-based routing** (not path-based)
- Each hostname/subdomain maps directly to a specific service
- SSE (Server-Sent Events) endpoints work seamlessly through the tunnel
- NodePort services (e.g., port 30091) available for local cluster access

## DNS Configuration

After deployment, configure DNS CNAMEs in Cloudflare:

### Main Domains

1. **pudim.dev**
   ```
   Type: CNAME
   Name: @ (or pudim.dev)
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

2. **luismachadoreis.dev**
   ```
   Type: CNAME
   Name: @ (or luismachadoreis.dev)
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

3. **carimbo.vip**
   ```
   Type: CNAME
   Name: @ (or carimbo.vip)
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

### Subdomains (Application Services)

4. **prompts.luismachadoreis.dev** (MCP Blueprint Prompts)
   ```
   Type: CNAME
   Name: prompts
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

### Brickfolio PROD (brickfolio.online zone)

5. **app.brickfolio.online** (PROD frontend)
   ```
   Type: CNAME
   Name: app
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

6. **api.brickfolio.online** (PROD API)
   ```
   Type: CNAME
   Name: api
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

### Brickfolio QA (brickfolio-qa.online zone)

> These are on a **separate zone** (`brickfolio-qa.online`) in Cloudflare.

7. **app.brickfolio-qa.online** (QA frontend)
   ```
   Type: CNAME
   Name: app
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

8. **api.brickfolio-qa.online** (QA API)
   ```
   Type: CNAME
   Name: api
   Content: <your-tunnel-uuid>.cfargotunnel.com
   Proxy: Yes (Orange cloud)
   ```

### Get Tunnel UUID

From Cloudflare Dashboard: Zero Trust > Networks > Tunnels > Your Tunnel > Copy UUID

### Adding New Subdomains

To add a new subdomain for an application service:

1. **Update Cloudflare Tunnel config** in `modules/cloudflare-tunnel/main.tf`:
   ```yaml
   - hostname: subdomain.yourdomain.com
     service: http://your-service.your-namespace.svc.cluster.local:port
   ```

2. **Apply Terraform changes**:
   ```bash
   terraform apply
   ```

3. **Add DNS CNAME** in Cloudflare pointing to your tunnel UUID

**Note**: Cloudflare Tunnel only supports hostname-based routing. Each subdomain must be configured separately in the tunnel ingress rules.

## Updating Site Content

Recommended: CI/CD builds and pushes a Docker image (e.g., to GHCR), then roll out the new image.

```bash
# Roll out via kubectl (example)
kubectl -n pudim-dev set image deployment/pudim-dev nginx=ghcr.io/ORG/pudim:latest
kubectl -n pudim-dev rollout status deployment/pudim-dev --timeout=120s

# Or set images in terraform.tfvars and apply
pudim_site_image             = "ghcr.io/ORG/pudim:latest"
luismachadoreis_site_image   = "ghcr.io/ORG/luis:latest"
carimbo_site_image           = "ghcr.io/ORG/carimbo:latest"
```

## Customization

### Add a New Site

1. **Create a new domain module** in `terraform/domains/newsite-com/`:

```bash
mkdir -p terraform/domains/newsite-com
```

2. **Create `domains/newsite-com/main.tf`**:

```hcl
# Create namespace
resource "kubernetes_namespace" "newsite_com" {
  metadata {
    name = "newsite-com"
    labels = {
      name        = "newsite-com"
      domain      = "newsite.com"
      environment = "production"
      managed-by  = "terraform"
    }
  }
}

# Deploy site
module "newsite_com_site" {
  source = "../../modules/nginx-static-site"
  
  site_name    = "newsite-com"
  domain       = "newsite.com"
  namespace    = kubernetes_namespace.newsite_com.metadata[0].name
  environment  = "production"
  replicas     = 3
  enable_nfs   = var.enable_nfs_storage
  storage_class = var.storage_class
  storage_size = "1Gi"
}
```

3. **Update root `main.tf`** to call the new domain module:

```hcl
module "newsite_com" {
  source = "./domains/newsite-com"
  
  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class
}
```

4. **Update Cloudflare Tunnel config** in `modules/cloudflare-tunnel/main.tf`:

```yaml
- hostname: newsite.com
  service: http://static-site.newsite-com.svc.cluster.local:80
```

5. **Apply changes**:

```bash
cd terraform
terraform apply
```

### Adjust Resources

Edit site-specific resource limits in `main.tf`:

```hcl
module "pudim_dev" {
  source = "./modules/nginx-static-site"
  
  # ... other vars ...
  
  resource_limits_cpu      = "200m"
  resource_limits_memory   = "256Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"
}
```

### Change Replica Count

```hcl
module "pudim_dev" {
  source = "./modules/nginx-static-site"
  
  replicas = 3  # Increase from 2 to 3
  
  # ... other vars ...
}
```

## Monitoring

### View Logs

```bash
# Site logs
kubectl logs -n pudim-dev -l app=pudim-dev --tail=50 -f

# Tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel --tail=50 -f

# Or use helper
./scripts/terraform-helper.sh logs pudim-dev
```

### Check Status

```bash
# All sites overview
kubectl get pods -A | grep -E "(pudim|luis|carimbo)"

# Specific namespace
kubectl get all -n pudim-dev

# All deployments
kubectl get deployments -A | grep -E "(pudim|luis|carimbo)"

# All services
kubectl get svc -A | grep static-site

# Or use helper
./scripts/terraform-helper.sh status
```

### Tunnel Metrics

The Cloudflare Tunnel exposes metrics on port 2000:

```bash
kubectl port-forward -n cloudflare-tunnel svc/cloudflare-tunnel-metrics 2000:2000

# Access metrics at http://localhost:2000/metrics
```

## Troubleshooting

### Sites Not Accessible

1. **Check pods are running**:
   ```bash
   kubectl get pods -n pudim-dev
   kubectl get pods -n cloudflare-tunnel
   ```

2. **Check tunnel status**:
   ```bash
   kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel
   ```

3. **Verify DNS**:
   ```bash
   dig pudim.dev
   curl -I https://pudim.dev
   ```

4. **Test internal connectivity**:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
     curl http://static-site.pudim-dev.svc.cluster.local
   ```

### PVC Not Binding

```bash
# Check PVC status (all namespaces)
kubectl get pvc -A

# Describe specific PVC
kubectl describe pvc pudim-dev-content -n pudim-dev

# Check StorageClass
kubectl get storageclass nfs-client

# Check NFS provisioner
kubectl get pods -n nfs-system
```

### Terraform State Issues

```bash
# Refresh state
terraform refresh

# Show state
terraform show

# List resources
terraform state list

# Import existing resource (if needed)
terraform import module.pudim_dev.kubernetes_namespace.pudim_dev pudim-dev
```

## Maintenance

### Update Nginx Image

Edit `domains/pudim-dev/main.tf`:

```hcl
module "pudim_dev_site" {
  source = "../../modules/nginx-static-site"
  
  nginx_image = "nginx:1.25-alpine"  # Specify version
  
  # ... other vars ...
}
```

Apply:
```bash
cd terraform
terraform apply
```

### Backup Content

If you enable NFS for any site, back up the volume data accordingly.

### Destroy Everything

⚠️ **Warning**: This will delete all sites and content!

```bash
terraform destroy
```

Or use helper:
```bash
./scripts/terraform-helper.sh destroy
```

## Terraform Commands Reference

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Show current state
terraform show

# Refresh state
terraform refresh

# Destroy resources
terraform destroy

# List resources in state
terraform state list

# Show specific resource
terraform state show kubernetes_deployment.pudim_dev
```

## Helper Script

A helper script is available for common operations:

```bash
# Show help
./scripts/terraform-helper.sh help

# Initialize
./scripts/terraform-helper.sh init

# Plan
./scripts/terraform-helper.sh plan

# Apply
./scripts/terraform-helper.sh apply

# Show status
./scripts/terraform-helper.sh status

# List sites
./scripts/terraform-helper.sh list-sites

# Update content
./scripts/terraform-helper.sh update-content pudim-dev ./index.html

# Show logs
./scripts/terraform-helper.sh logs pudim-dev
```

## Security

### Sensitive Data

- `terraform.tfvars` is gitignored (contains tunnel token)
- Tunnel token is stored as a Kubernetes Secret
- Never commit `terraform.tfstate` (contains sensitive data)

### Best Practices

1. **Use remote state** for team collaboration:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "homelabs/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

2. **Rotate tunnel tokens** periodically

3. **Use RBAC** to limit access to namespaces

4. **Enable Pod Security Policies**

## Cost Optimization

### Resource Requests

Current configuration uses minimal resources:
- CPU: 50m per container
- Memory: 64Mi per container

For production, consider:
- Horizontal Pod Autoscaling (HPA)
- Vertical Pod Autoscaling (VPA)
- Resource quotas per namespace

### Storage

- Sites serve content from container images by default
- NFS is optional for cases requiring shared RW data

## Next Steps

1. ✅ Deploy infrastructure with Terraform
2. ✅ Configure DNS CNAMEs
3. 📝 Upload your site content
4. 🔒 Add SSL/TLS (handled by Cloudflare)
5. 📊 Set up monitoring (Grafana dashboards)
6. 🚀 Deploy more sites as needed

## Support

For issues or questions:
- Check logs: `kubectl logs -n static-sites <pod-name>`
- Review Terraform output: `terraform output`
- Consult documentation: `docs/`

---

**Managed by Terraform** | **Version**: 1.0 | **Last Updated**: Nov 2025

## App Service Module

Path: `terraform/modules/app-service`

A generic module for deploying application services (APIs, SSE servers, backend services, etc.).

### Features

- Kubernetes Deployment with configurable replicas
- ClusterIP Service for internal cluster access
- Optional NodePort Service for external/local access
- Optional NFS persistent storage
- Horizontal Pod Autoscaling (HPA) support
- Configurable resource limits and health checks
- Support for ConfigMap-based environment variables
- Private registry support (imagePullSecrets)

### Example: MCP Blueprint Prompts Service

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
  image_pull_secret_name = try(kubernetes_secret_v1.ghcr_pull[0].metadata[0].name, null)

  container_port    = 9000
  service_port      = 9000
  health_check_path = "/"
  health_check_port = 9000

  resource_limits_cpu      = "500m"
  resource_limits_memory   = "512Mi"
  resource_requests_cpu    = "100m"
  resource_requests_memory = "128Mi"

  # NodePort for external access (accessible via cluster IP:30091)
  node_port = 30091

  depends_on_resources = [kubernetes_namespace.luismachadoreis_dev]
}
```

### Cloudflare Tunnel Configuration

For SSE endpoints or application services, configure subdomain routing:

```yaml
# In modules/cloudflare-tunnel/main.tf
- hostname: prompts.luismachadoreis.dev
  service: http://mcp-blueprint-prompts.luismachadoreis-dev.svc.cluster.local:9000
```

### Important Notes

- **Hostname-based routing**: Cloudflare Tunnel routes by hostname/subdomain, not by path
- **SSE Support**: Server-Sent Events work seamlessly through the tunnel
- **NodePort**: Useful for local development/testing (e.g., `http://192.168.7.200:30091`)
- **Health Checks**: Configure appropriate paths for liveness/readiness probes

### Troubleshooting: API pod crash / restarts

When API pods are in CrashLoopBackOff or not becoming Ready:

1. **Why the container exited**  
   `kubectl describe pod -n <namespace> -l app=api`  
   Check **Last State** / **Reason** (e.g. OOMKilled, or exit code 137/143 from probes).

2. **Restarts**  
   `kubectl get pod -n <namespace> -l app=api -o wide`  
   Check **RESTARTS** and **STATUS**.

3. **Probe config**  
   In the Deployment (or Terraform app-service module) check `livenessProbe`, `readinessProbe`, and whether `startupProbe` is set.  
   If there is no startup probe and `initialDelaySeconds` is short (e.g. 30–60s), the app can be killed during slow startup. The brickfolio API uses a startup probe to avoid this.

### Brickfolio QA/PROD: Common Operations

**Check all pods:**
```bash
kubectl get pods -n brickfolio-online-prod
kubectl get pods -n brickfolio-online-qa
```

**Restart API (e.g. after Secret update):**
```bash
kubectl rollout restart deployment/api -n brickfolio-online-prod
kubectl rollout restart deployment/api -n brickfolio-online-qa
```

**Restart App (e.g. after ConfigMap update):**
```bash
kubectl rollout restart deployment/app -n brickfolio-online-prod
kubectl rollout restart deployment/app -n brickfolio-online-qa
```

> After restarting the app, **purge the Cloudflare cache** for `runtime-config.js` so browsers pick up the new config:
> - Cloudflare Dashboard → brickfolio.online → Caching → Cache Purge → Custom Purge
> - URL: `https://app.brickfolio.online/runtime-config.js`

**View API logs:**
```bash
kubectl logs -n brickfolio-online-prod -l app=api -c api --tail=100
kubectl logs -n brickfolio-online-qa -l app=api -c api --tail=100
```

**Check env vars in the app pod:**
```bash
kubectl exec -n brickfolio-online-prod deployment/app -- env | grep VITE_
kubectl get configmap app-config -n brickfolio-online-prod -o yaml
```

**Check runtime-config.js served by the cluster:**
```bash
kubectl exec -n brickfolio-online-prod deployment/app -- cat /usr/share/nginx/html/runtime-config.js
```

**Check runtime-config.js served publicly (bypasses pod, shows Cloudflare cache):**
```bash
curl -s https://app.brickfolio.online/runtime-config.js
```

**JWT secret requirement:**  
The API's `JWT_SECRET` must be **at least 32 characters** (256 bits). A shorter secret causes `WeakKeyException` on startup and the pod will crash. Set via:
```bash
export TF_VAR_brickfolio_prod_api_jwt_secret="<32+ char secret>"
```

## Nginx Redirector Module

Path: `terraform/modules/nginx-redirector`

- Inputs
  - `namespace` (string): Target namespace (e.g., `redirects`)
  - `name` (string): App name (default: `redirector`)
  - `replicas` (number): Initial replicas (default: `1`) — HPA controls scaling thereafter
  - `rules` (list): Redirect rules
    - `sources` (list[string]): Hostnames; wildcards supported via `*.domain.tld`
    - `target` (string): Canonical domain (no scheme)
    - `code` (number, optional): HTTP code (default: `301`)
  - `min_replicas` (default `1`), `max_replicas` (default `4`)
  - `target_cpu_utilization_percentage` (default `60`)
  - `target_memory_utilization_percentage` (default `70`)

- Behavior
  - Generates Nginx server blocks for apex and wildcard sources
  - Preserves path and query; always redirects to HTTPS
  - HPA scales between 1 and 4 pods based on CPU/Mem utilization

- Example
```hcl
resource "kubernetes_namespace" "redirects" {
  metadata { name = "redirects" }
}

module "redirects" {
  source    = "../modules/nginx-redirector"
  namespace = kubernetes_namespace.redirects.metadata[0].name

  rules = [
    { sources = ["luismachadoreis.dev.br", "*.luismachadoreis.dev.br"], target = "luismachadoreis.dev", code = 301 },
    { sources = ["pudim.dev.br", "*.pudim.dev.br"],                   target = "pudim.dev",            code = 301 },
    { sources = ["carimbovip.com.br", "*.carimbovip.com.br", "carimbovip.com", "*.carimbovip.com"], target = "carimbo.vip", code = 301 },
  ]

  min_replicas = 1
  max_replicas = 4
}
```

- Verify
```bash
kubectl -n redirects get deploy redirector
kubectl -n redirects get hpa redirector-hpa
kubectl -n redirects run curl --image=curlimages/curl:8.10.1 --rm -i --restart=Never -- \
  sh -lc "curl -sSI -H 'Host: pudim.dev.br' 'http://redirector.redirects.svc.cluster.local/'"
```

