terraform {
  required_version = ">= 1.3.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}
