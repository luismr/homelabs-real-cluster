terraform {
  required_version = ">= 1.11.0"

  backend "s3" {
    bucket       = "homelabs-cluster"
    key          = "backend/terraform.tfstate"
    region       = "us-east-1"
    profile      = "singularideas-com-br"
    use_lockfile = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

