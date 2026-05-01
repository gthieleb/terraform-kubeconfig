# Kubeconfig Fetch Module

This module retrieves a kubeconfig from a remote Kubernetes control plane
node (k3s or rke2) over SSH. It can optionally rewrite the API server
address and rename the context/user/cluster entries to a custom name so
that no "default" entry remains in the output config.

## Usage

```hcl
module "kubeconfig" {
  source = "..."

  remote_host = "10.0.0.10"
  private_key = file("~/.ssh/id_rsa")

  # Optional: rewrite the kubeconfig server entry
  kubernetes_master_nodes = ["10.0.0.10", "10.0.0.11"]
  replace_server          = true

  # Optional: rename context/user/cluster so no "default" remains
  kubeconfig_name = "prod-eu1"
}
```

## Rename context/user/cluster (no "default")

Set `kubeconfig_name` to rename the first context, user, and cluster
entries (and `current-context`) to the same name. This ensures the output
kubeconfig no longer includes the default names produced by k3s/rke2.

See [examples/named-kubeconfig](examples/named-kubeconfig).

## Requirements

- Terraform >= 1.3.0

## Providers

- loafoe/ssh 2.7.0
- hashicorp/random 3.8.1
- hashicorp/local 2.6.2

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| private_key | SSH private key of a Kubernetes master node | `string` | n/a | yes |
| bastion_host | Bastion host to use for SSH tunneling | `string` | `null` | no |
| bastion_user | SSH user for the bastion host | `string` | `null` | no |
| bastion_private_key | Private key for SSH access to the bastion host | `string` | `null` | no |
| remote_host | Kubernetes master node to pull the kubeconfig from | `string` | n/a | yes |
| remote_user | SSH user for the remote host | `string` | `"rancher"` | no |
| remote_port | SSH port for the remote host | `number` | `22` | no |
| remote_command_list | Override the commands used to retrieve kubeconfig | `list(string)` | `[]` | no |
| kubernetes_distribution | Kubernetes distribution used to choose defaults | `string` | `"k3s"` | no |
| default_remote_command_list | Default commands per distribution | `map(list(string))` | see variables.tf | no |
| kubernetes_master_nodes | DNS or IP list of master nodes | `list(string)` | `[]` | no |
| replace_server | Replace the server property in kubeconfig | `bool` | `true` | no |
| kubeconfig_save_file | Write kubeconfig to a local file | `bool` | `false` | no |
| kubeconfig_file_path | Path to write local kubeconfig | `string` | `null` | no |
| kubeconfig_name | Base name used to rename context/user/cluster | `string` | `null` | no |
| kubeconfig_context_name | **Legacy:** additional context name | `string` | `null` | no |
| add_named_context | **Legacy:** add extra context, keep default | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| kubeconfig_file_path | Kubeconfig file path (if written) |
| kubeconfig | Kubeconfig YAML content |
| kube_config | Legacy alias for kubeconfig |
| config | Kubeconfig decoded from YAML |
| remote_command_list | Commands executed to fetch the kubeconfig |
