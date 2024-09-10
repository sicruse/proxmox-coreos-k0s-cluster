variable "name" {
  description = "Name of node"
  type        = string
}

variable "memory" {
  description = "Amount of memory needed"
  type        = string
}

variable "vcpus" {
  description = "Number of vcpus"
  type        = number
}

variable "sockets" {
  description = "Number of sockets"
  type        = number
}

variable "autostart" {
  description = "Enable/Disable VM start on host bootup"
  type        = bool
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

variable "snippet_storage_path" {
  description = "File system path for ProxMox snippets"
  type        = string
}
