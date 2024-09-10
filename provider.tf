terraform {

#   cloud {
#     organization = "1104-Lab"

#     workspaces {
#       name = "1104-Kubernetes"
#     }
#   }

  required_providers {

      proxmox = {
      source = "bpg/proxmox"
      # See this file for good configuration documentation
      # https://github.com/bpg/terraform-provider-proxmox/blob/ed3bdb5187dbf5588eedfc8d9ed193ab108edd64/docs/resources/virtual_environment_vm.md
      # https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
    }  
  }

  required_version = "~> 1.2"
}

provider "proxmox" {
  endpoint = "https://${var.proxmox.host}:8006/api2/json"
  username = "${var.proxmox.user}@pam"
  password = var.proxmox.password
  insecure = var.proxmox.tls_insecure
  # TODO - Refactor to use API token rather than username / password
  # api_token = SOURCED FROM PROXMOX_VE_API_TOKEN ENVIRONMENT VARIABLE

  ssh {
    agent = true
  }
}
