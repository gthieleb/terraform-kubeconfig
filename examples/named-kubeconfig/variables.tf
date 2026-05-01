variable "remote_host" {
  description = "Kubernetes master node to pull the kubeconfig from"
  type        = string
  default     = "10.0.0.10"
}

variable "private_key" {
  description = "SSH private key for the remote host"
  type        = string
  default     = "example-private-key"
}

variable "kubeconfig_name" {
  description = "Name to apply to context, user, and cluster"
  type        = string
  default     = "demo-cluster"
}
