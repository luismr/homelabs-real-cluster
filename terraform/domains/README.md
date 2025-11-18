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

## Benefits

1. **Isolation** - Each domain is self-contained
2. **Scalability** - Easy to add more applications per domain
3. **Maintainability** - Changes to one domain don't affect others
4. **Clarity** - Clear separation of concerns

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

# Add an API backend
module "pudim_api" {
  source = "../../modules/api-backend"
  
  namespace = kubernetes_namespace.pudim_dev.metadata[0].name
  domain    = "api.pudim.dev"
  ...
}
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

