terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }  

    ct = {
      source  = "poseidon/ct"
      version = "~> 0.13"
    }
  }

  required_version = "~> 1.2"
}
