variable "host_name" {
  description = "Host name for Ignition config"
  type        = string
}

variable "proxmox_host" {
  description = "IP address for proxmox"
  type        = string
}

variable "proxmox_snippet_datastore_id" {
  description = "Proxmox storage identifier for Snippets"
  type = string
}

variable "ssh_public_key_path" {
  description = "Path to public ssh key used to connect to cluster nodes"
  type        = string
}