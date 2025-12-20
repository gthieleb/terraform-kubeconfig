variable "private_key" {
  type        = string
  description = "SSH Key of one of the Kubernetes Master Node"
}

variable "bastion_host" {
  type        = string
  description = "Bastion host to use for SSH tunneling"
  default     = null
}

variable "bastion_user" {
  type        = string
  description = "SSH user for the bastion host"
  default     = null
}

variable "bastion_private_key" {
  type        = string
  description = "Private key for SSH access to the bastion host"
  default     = null
}

variable "remote_host" {
  type        = string
  description = "Kubernetes Master Node to pull the kubeconfig"
}

variable "remote_user" {
  type    = string
  default = "rancher"
}

variable "remote_port" {
  type    = string
  default = 22
}

variable "remote_command_list" {
  description = <<EOF
    Default remote commands used to retreive the kubeconfig on the remote system. 
  EOF  
  type        = list(string)
  default     = []
}

variable "kubernetes_distribution" {
  type    = string
  default = "k3s"
}

variable "default_remote_command_list" {
  type        = map(list(string))
  description = "Default commands for kubernetes distribution"
  default = {
    "k3s"  = ["cloud-init status --wait > /dev/null && cat /etc/rancher/k3s/k3s.yaml"]
    "rke2" = ["cloud-init status --wait > /dev/null && cat /etc/rancher/rke2/rke2.yaml"]
  }
}

variable "kubernetes_master_nodes" {
  type        = list(string)
  description = "dns or ip address list of the master nodes"
  default     = []
}

variable "replace_server" {
  type        = bool
  description = "Replace server property"
  default     = true
}

variable "kubeconfig_save_file" {
  type    = bool
  default = false
}

variable "kubeconfig_file_path" {
  description = "Path to write local kubeconfig"
  type        = string
  default     = null
}

variable "kubeconfig_context_name" {
  type        = string
  description = "Name to use for the kubeconfig context"
  default     = null
}

variable "add_named_context" {
  type        = bool
  description = "Add a new named context instead of updating the default one"
  default     = false
}
