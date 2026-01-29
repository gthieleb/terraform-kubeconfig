output "kubeconfig_file_path" {
  description = "Kubeconfig file path (if written)"
  sensitive   = true
  value       = local.kubeconfig_file_path
}

output "kubeconfig" {
  description = "Kubeconfig YAML content"
  sensitive   = true
  value       = local.kubeconfig_content
}

output "kube_config" {
  description = "Legacy alias for kubeconfig"
  sensitive   = true
  value       = local.kubeconfig_content
}

output "config" {
  description = "Kubeconfig decoded from YAML"
  sensitive   = true
  value       = yamldecode(local.kubeconfig_content)
}

output "remote_command_list" {
  description = "Commands executed to fetch the kubeconfig"
  value       = local.remote_command_list
}
