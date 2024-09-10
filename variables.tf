################################################################################
## Proxmox hypervisor configuration
variable "proxmox" {
  type = object({
    host                 = string
    template_node        = string
    user                 = string
    password             = string
    ssh_public_key_path  = string
    ssh_private_key_path = string
    tls_insecure         = bool
    network_bridge       = string
    iso_datastore_id     = string
    snippet_datastore_id = string
    snippet_storage_path = string
    vm_disk_datastore_id = string
    iso_storage_path     = string
  })
  sensitive = true
}

# Kubernetes Configuration
variable "kubernetes" {
  type = object({
    ssh_public_key_path = string
    master = object({
      count       = number
      memory      = string
      vcpus       = number
      sockets     = number
      target_node = string
    })
    worker = object({
      count       = number
      memory      = string
      vcpus       = number
      sockets     = number
      target_node = string
    })
    autostart = bool
  })
}

# HA Proxy Configuration
variable "ha_proxy" {
  type = object({
    user           = string
    target_node    = string
    template_vm_id = string
    ip_address     = string
    gateway        = string
  })
}

# CoreOS ProxMox Template Configuration
variable "coreos_template" {
  type = object({
    vm_id                 = number
    memory                = number
    network_bridge        = string
    additional_disk_size  = string
    cloud_init_user       = string
    ssh_public_keys       = string
    template_name         = string
    template_vm_id        = string
  })
}
