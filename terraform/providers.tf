provider "kubernetes" {
  config_path = "~/.kube/config-homelabs"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config-homelabs"
  }
}

