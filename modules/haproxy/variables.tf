variable "ha_proxy_user" {
  description = "Username for proxy VM"
  type        = string
}
variable "default_network_bridge" {
  description = "Bridge to use when creating VMs in proxmox"
  type        = string
}

variable "template_node" {
  description = "Template source node name in proxmox"
  type        = string
}

variable "template_vm_id" {
  description = "ProxMox VM id for Ubuntu template image"
  type        = string
}

variable "target_node" {
  description = "Target node name in proxmox"
  type        = string
}

variable "proxmox_host" {
  description = "IP address for proxmox"
  type        = string
}

variable "proxmox_user" {
  description = "User name used to login proxmox"
  type        = string
}

variable "proxmox_password" {
  description = "Password used to login proxmox"
  type        = string
}

variable "public_key" {
  description = "Public ssh key used to connect to cluster nodes"
  type        = string
}

variable "proxmox_snippet_storage_path" {
  description = "File system path for ProxMox snippets"
  type        = string
}

variable "ip_address" {
  description = "IP address for proxy, e.g. '192/168.1.10/24'"
  type        = string
}

variable "gateway" {
  description = "Network gateway, e.g. 192.168.1.1"
  type        = string
}

variable "proxmox_snippet_datastore_id" {
  description = "Proxmox storage identifier for Snippets"
  type = string
}

variable "proxmox_vm_disk_datastore_id" {
  description = "Proxmox storage identifier for VM disks"
  type = string
}
