locals {

  remote_command_list = length(var.remote_command_list) > 0 ? var.remote_command_list : var.default_remote_command_list[var.kubernetes_distribution]

  kubeconfig_file_path = (var.kubeconfig_save_file ? var.kubeconfig_file_path != null ?
    startswith(var.kubeconfig_file_path, "/") || startswith(var.kubeconfig_file_path, "./") ?
    var.kubeconfig_file_path :
    pathexpand("~/.kube/${var.kubeconfig_file_path}") :
  pathexpand("~/.kube/${var.remote_host}-${random_integer.file_sfx.result}") : "")

  _master_nodes        = length(var.kubernetes_master_nodes) > 0 ? var.kubernetes_master_nodes : [var.remote_host]
  _master_nodes_joined = join(";", [for node in local._master_nodes : "https://${node}:6443"])


  _kubeconfig_decoded = yamldecode(ssh_sensitive_resource.kubeconfig.result)
  
  # Apply server replacement if needed
  # We're using the first cluster entry as that's the standard for k3s/rke2 kubeconfig files
  # which typically only have one cluster defined. Both k3s and rke2 generate kubeconfig files
  # with exactly one cluster entry by default.
  _kubeconfig_with_server = var.replace_server ? merge(local._kubeconfig_decoded, {
    clusters = length(local._kubeconfig_decoded.clusters) > 0 ? [
      merge(local._kubeconfig_decoded.clusters[0], {
        cluster = merge(local._kubeconfig_decoded.clusters[0].cluster, {
          server = local._master_nodes_joined
        })
      })
    ] : local._kubeconfig_decoded.clusters
  }) : local._kubeconfig_decoded
  
  # Apply context name changes if needed
  # We're adding a new named context rather than renaming the existing one.
  # This approach has several benefits:
  # 1. It preserves the original context, which maintains compatibility with tools that expect default names
  # 2. It adds our custom named context, which is more descriptive and user-friendly
  # 3. It allows users to switch between contexts as needed using kubectl config use-context
  # 4. It's safer than replacing the original context which could break existing workflows
  # 
  _kubeconfig_with_context = var.kubeconfig_context_name != null && var.add_named_context ? (
    merge(local._kubeconfig_with_server, {
      # Add a new named context while keeping the original
      contexts = length(local._kubeconfig_with_server.contexts) > 0 ? concat(
        local._kubeconfig_with_server.contexts,
        [
          {
            name = var.kubeconfig_context_name
            context = local._kubeconfig_with_server.contexts[0].context
          }
        ]
      ) : local._kubeconfig_with_server.contexts
    })
  ) : local._kubeconfig_with_server
  
  kubeconfig_content = yamlencode(local._kubeconfig_with_context)
}

resource "random_integer" "file_sfx" {
  min = 1111
  max = 9999
}

resource "ssh_sensitive_resource" "kubeconfig" {

  # The default behaviour is to run file blocks and commands at create time
  # You can also specify 'destroy' to run the commands at destroy time
  when = "create"

  host        = var.bastion_host != null ? var.bastion_host : var.remote_host
  user        = var.bastion_user != null ? var.bastion_user : var.remote_user
  private_key = var.bastion_private_key != null ? var.bastion_private_key : var.private_key

  timeout = "1m"

  commands = var.bastion_host != null ? [
    "ssh -o StrictHostKeyChecking=no -i ${var.private_key} ${var.remote_user}@${var.remote_host} '${join(" && ", local.remote_command_list)}'"
  ] : local.remote_command_list
}

resource "local_sensitive_file" "kubeconfig" {
  count = var.kubeconfig_save_file ? 1 : 0

  filename        = local.kubeconfig_file_path
  content         = local.kubeconfig_content
  file_permission = "0600"
}

output "kubeconfig_file_path" {
  description = "Kubeconfig"
  sensitive   = true
  value       = local.kubeconfig_file_path
}

output "kube_config" {
  description = "Kubeconfig Encoded"
  sensitive   = true
  value       = local.kubeconfig_content
}

output "config" {
  description = "Kubeconfig Decoded from YAML"
  sensitive   = true
  value       = yamldecode(local.kubeconfig_content)
}

output "remote_command_list" {
  value = local.remote_command_list
}
