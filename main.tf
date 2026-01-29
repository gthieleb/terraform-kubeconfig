locals {
  remote_command_list = length(var.remote_command_list) > 0 ? var.remote_command_list : var.default_remote_command_list[var.kubernetes_distribution]

  kubeconfig_default_path = pathexpand("~/.kube/${var.remote_host}-${random_integer.file_sfx.result}")
  kubeconfig_explicit_path = var.kubeconfig_file_path != null ? (
    startswith(var.kubeconfig_file_path, "/") || startswith(var.kubeconfig_file_path, "./") ? (
      var.kubeconfig_file_path
    ) : (
      pathexpand("~/.kube/${var.kubeconfig_file_path}")
    )
  ) : null
  kubeconfig_file_path = var.kubeconfig_save_file ? (
    coalesce(local.kubeconfig_explicit_path, local.kubeconfig_default_path)
  ) : ""

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

  # Rename context/user/cluster entries to avoid "default" in output.
  _kubeconfig_with_renamed_entries = var.kubeconfig_name != null ? merge(local._kubeconfig_with_server, {
    clusters = [
      for idx, cluster in try(local._kubeconfig_with_server.clusters, []) :
      idx == 0 ? merge(cluster, { name = var.kubeconfig_name }) : cluster
    ]
    users = [
      for idx, user in try(local._kubeconfig_with_server.users, []) :
      idx == 0 ? merge(user, { name = var.kubeconfig_name }) : user
    ]
    contexts = [
      for idx, context in try(local._kubeconfig_with_server.contexts, []) :
      idx == 0 ? merge(context, {
        name = var.kubeconfig_name
        context = merge(try(context.context, {}), {
          cluster = var.kubeconfig_name
          user    = var.kubeconfig_name
        })
      }) : context
    ]
    "current-context" = var.kubeconfig_name
  }) : local._kubeconfig_with_server

  # Legacy behavior: add a new named context while keeping the existing one.
  _kubeconfig_with_context = var.kubeconfig_context_name != null && var.add_named_context ? (
    merge(local._kubeconfig_with_renamed_entries, {
      contexts = length(try(local._kubeconfig_with_renamed_entries.contexts, [])) > 0 ? concat(
        try(local._kubeconfig_with_renamed_entries.contexts, []),
        [
          {
            name = var.kubeconfig_context_name
            context = local._kubeconfig_with_renamed_entries.contexts[0].context
          }
        ]
      ) : try(local._kubeconfig_with_renamed_entries.contexts, [])
    })
  ) : local._kubeconfig_with_renamed_entries

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

  bastion_host        = var.bastion_host
  bastion_user        = var.bastion_user
  bastion_private_key = var.bastion_private_key

  host        = var.remote_host
  user        = var.remote_user
  port        = var.remote_port
  private_key = var.private_key

  timeout = "1m"

  commands = local.remote_command_list

}

resource "local_sensitive_file" "kubeconfig" {
  count = var.kubeconfig_save_file ? 1 : 0

  filename        = local.kubeconfig_file_path
  content         = local.kubeconfig_content
  file_permission = "0600"
}
