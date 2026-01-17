# Domain Modules

This directory contains Terraform modules for each domain, organized for better separation and maintainability.

## Structure

Each domain has its own folder with:
- `main.tf` - Namespace and application resources for the domain
- `variables.tf` - Input variables for the domain
- `outputs.tf` - Output values from the domain

```
domains/
├── README.md (this file)
├── pudim-dev/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── luismachadoreis-dev/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── carimbo-vip/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## Domain Services

Each domain can host multiple types of services:

1. **Static Sites** - Nginx-based websites (using `nginx-static-site` module)
2. **Application Services** - Backend APIs, SSE servers, etc. (using `app-service` module)
3. **Forms** - Contact forms and data collection
4. **Database Services** - PostgreSQL, Redis, etc.
5. **N8N Workflows** - Automation and integrations

### Example: luismachadoreis-dev

This domain hosts multiple services:
- **Static Site** (luismachadoreis.dev) - Main website
- **MCP Blueprint Prompts** (prompts.luismachadoreis.dev) - MCP server with SSE endpoint

## Benefits

1. **Isolation** - Each domain is self-contained
2. **Scalability** - Easy to add more applications per domain
3. **Maintainability** - Changes to one domain don't affect others
4. **Clarity** - Clear separation of concerns
5. **Flexibility** - Mix static sites with dynamic application services

## Usage

### View domain configuration
```bash
cd terraform/domains/pudim-dev
cat main.tf
```

### Add new application to a domain

Edit the domain's `main.tf` to add more modules:

```terraform
# In domains/pudim-dev/main.tf

# Add an API backend using app-service module
module "pudim_api" {
  source = "../../modules/app-service"
  
  app_name           = "api"
  domain             = "api.pudim.dev"
  namespace          = kubernetes_namespace.pudim_dev.metadata[0].name
  environment        = "production"
  
  app_image          = "your-registry/pudim-api:latest"
  container_port     = 8000
  service_port       = 8000
  
  # Optional: Enable NodePort for local access
  node_port          = 30100
  
  depends_on_resources = [kubernetes_namespace.pudim_dev]
}
```

Then update Cloudflare Tunnel configuration in `modules/cloudflare-tunnel/main.tf`:
```yaml
- hostname: api.pudim.dev
  service: http://api.pudim-dev.svc.cluster.local:8000
```

### Add new domain

1. Create directory: `mkdir domains/newdomain-com`
2. Create files: `main.tf`, `variables.tf`, `outputs.tf`
3. Add module call in root `main.tf`:
```terraform
module "newdomain_com" {
  source = "./domains/newdomain-com"
  
  enable_nfs_storage = var.enable_nfs_storage
  storage_class      = var.storage_class
}
```

## Root main.tf

The root `terraform/main.tf` orchestrates all domains:

```terraform
module "pudim_dev" {
  source = "./domains/pudim-dev"
  ...
}

module "luismachadoreis_dev" {
  source = "./domains/luismachadoreis-dev"
  ...
}

module "carimbo_vip" {
  source = "./domains/carimbo-vip"
  ...
}
```

## Testing

After changes, always run:
```bash
cd terraform/
terraform plan    # Verify no unwanted changes
terraform apply   # Apply the changes
```

