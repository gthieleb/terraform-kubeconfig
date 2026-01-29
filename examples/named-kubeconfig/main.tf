terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "ssh" {}

module "kubeconfig" {
  source = "../.."

  remote_host = var.remote_host
  private_key = var.private_key

  # Rename context/user/cluster to avoid "default"
  kubeconfig_name = var.kubeconfig_name
}

output "kubeconfig_yaml" {
  description = "Rendered kubeconfig with renamed entries"
  sensitive   = true
  value       = module.kubeconfig.kubeconfig
}
